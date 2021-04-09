# Created by: Sergey Osokin <osa@FreeBSD.org>
# $FreeBSD$

MASTER_SITES=	https://unit.nginx.org/download/:unit
PKGNAMESUFFIX=	-${UNIT_MODNAME}${FLAVOR:S|node||g}
DISTFILES=	unit-${UNIT_VERSION}${EXTRACT_SUFX}:unit \
		node-gyp-${NODE_GYP_VERSION}${EXTRACT_SUFX}:node_gyp

COMMENT=	NodeJS module for NGINX Unit

LICENSE=	APACHE20
LICENSE_FILE=	${WRKSRC}/LICENSE

FLAVORS=	node node14 node12 node10
FLAVOR?=	${FLAVORS:[1]}

node10_BUILD_DEPENDS=	node:www/node10 \
			npm:www/npm-node10
node12_BUILD_DEPENDS=	node:www/node12 \
			npm:www/npm-node12
node14_BUILD_DEPENDS=	node:www/node14 \
			npm:www/npm-node14
node_BUILD_DEPENDS=	node:www/node \
			npm:www/npm

node10_RUN_DEPENDS=	node:www/node10
node12_RUN_DEPENDS=	node:www/node12
node14_RUN_DEPENDS=	node:www/node14
node_RUN_DEPENDS=	node:www/node

node10_CONFLICTS_INSTALL=	unit-${UNIT_MODNAME} unit-${UNIT_MODNAME}14 unit-${UNIT_MODNAME}12
node12_CONFLICTS_INSTALL=	unit-${UNIT_MODNAME} unit-${UNIT_MODNAME}14 unit-${UNIT_MODNAME}10
node14_CONFLICTS_INSTALL=	unit-${UNIT_MODNAME} unit-${UNIT_MODNAME}12 unit-${UNIT_MODNAME}10
node_CONFLICTS_INSTALL=		unit-${UNIT_MODNAME}14 unit-${UNIT_MODNAME}12 unit-${UNIT_MODNAME}10

node10_DESC=	Use www/node10 as backend
node12_DESC=	Use www/node12 as backend
node14_DESC=	Use www/node14 as backend
node_DESC=	Use www/node as backend

BUILD_DEPENDS+=	${LOCALBASE}/lib/libunit.a:devel/libunit
RUN_DEPENDS+=	unitd:www/unit

USES=		python:build

DISTINFO_FILE=	${.CURDIR}/distinfo

PATCHDIR=	${.CURDIR}/files

UNIT_VERSION=		1.23.0
NODE_GYP_VERSION=	7.1.2

USE_GITHUB=	nodefault
GH_TUPLE=	nodejs:node-gyp:${NODE_GYP_VERSION}

OPTIONS_DEFINE=	# reset

UNIT_MODNAME=	nodejs
MAKE_ENV+=	DISTDIR="${DISTDIR}" \
		NODEJS_VERSION="${NODEJS_VERSION}" \
		PYTHON="${PYTHON_CMD}" \
		_DEVDIR="${_DEVDIR}"

USE_RC_SUBR?=	# reset to empty

MASTERDIR=	${.CURDIR}/../unit

PLIST_FILES=	# reset
PLIST_DIRS=	# reset
PLIST=		${.CURDIR}/pkg-plist

_NODECMD=	${LOCALBASE}/bin/node --version
_DEVDIR:=	${WRKDIR}/.devdir

post-extract:
	${MKDIR} ${_DEVDIR}/bin
	(cd ${WRKDIR}/node-gyp-${NODE_GYP_VERSION} && \
	${COPYTREE_SHARE} . ${_DEVDIR}/lib/node_modules/node-gyp \
	"! ( -name \.* -or -path *\/\.github\/* -or -name test -or -path *\/test\/* )")
	${RLN} ${_DEVDIR}/lib/node_modules/node-gyp/bin/node-gyp.js \
		${_DEVDIR}/bin/node-gyp && \
	${CHMOD} 0755 ${_DEVDIR}/bin/node-gyp && \
	${LN} -s ${LOCALBASE}/lib/node_modules/npm/node_modules \
		${_DEVDIR}/lib/node_modules/node-gyp/node_modules

post-patch:
	${REINPLACE_CMD} -i "" -e "s|%%PREFIX%%|${PREFIX}|g" \
		${WRKSRC}/src/nodejs/unit-http/binding.gyp
	${REINPLACE_CMD} -i "" -e "s|%%DEVDIR%%|${_DEVDIR}|g" \
		${WRKSRC}/src/nodejs/unit-http/package.json

pre-configure:
	(_NODEVER=$$(${_NODECMD} | ${SED} -n 's|^v\(.*\)|\1|p') && \
	${MKDIR} ${_DEVDIR}/$${_NODEVER}/include && \
	${RLN} ${LOCALBASE}/include/node ${_DEVDIR}/$${_NODEVER}/include/node && \
	${ECHO} "9" > ${_DEVDIR}/$${_NODEVER}/installVersion \
	)

post-configure:
	cd ${CONFIGURE_WRKSRC} && \
	${SETENV} ${MAKE_ENV} ${CONFIGURE_CMD} nodejs \
		--node-gyp=${_DEVDIR}/bin/node-gyp \
		--local=${STAGEDIR}${PREFIX}/lib/node_modules/unit-http

do-build:
	cd ${CONFIGURE_WRKSRC} && ${SETENV} ${MAKE_ENV} ${MAKE} node

do-install:
	cd ${CONFIGURE_WRKSRC} && ${SETENV} ${MAKE_ENV} ${MAKE} node-local-install

post-install:
	${INSTALL_DATA} ${WRKSRC}/src/nodejs/unit-http/package.json.orig \
		${STAGEDIR}${PREFIX}/lib/node_modules/unit-http/package.json
	${RM} -rf ${STAGEDIR}${PREFIX}/lib/node_modules/unit-http/build/Release/.deps \
		${STAGEDIR}${PREFIX}/lib/node_modules/unit-http/build/Release/obj.target
	${RM} ${STAGEDIR}${PREFIX}/lib/node_modules/unit-http/build/Makefile \
		${STAGEDIR}${PREFIX}/lib/node_modules/unit-http/build/Release/binding.Makefile \
		${STAGEDIR}${PREFIX}/lib/node_modules/unit-http/build/Release/config.gypi \
		${STAGEDIR}${PREFIX}/lib/node_modules/unit-http/build/Release/unit-http.target.mk \
		${STAGEDIR}${PREFIX}/lib/package-lock.json
	${STRIP_CMD} ${STAGEDIR}${PREFIX}/lib/node_modules/unit-http/build/Release/unit-http.node

.include "${MASTERDIR}/Makefile"
