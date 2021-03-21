# Created by: Sergey Osokin <osa@FreeBSD.org>
# $FreeBSD$

MASTER_SITES=	https://unit.nginx.org/download/:unit
PKGNAMESUFFIX=	-${UNIT_MODNAME}
DISTFILES=	unit-${UNIT_VERSION}${EXTRACT_SUFX}:unit \
		node-gyp-${NODE_GYP_VERSION}${EXTRACT_SUFX}:node_gyp

COMMENT=	NodeJS module for NGINX Unit

DISTINFO_FILE=	${.CURDIR}/distinfo

PATCHDIR=	${.CURDIR}/files

UNIT_MODNAME=	nodejs

BUILD_DEPENDS=	${LOCALBASE}/lib/libunit.a:devel/libunit \
		node:www/node \
		npm:www/npm
RUN_DEPENDS=	unitd:www/unit

UNIT_VERSION=		1.22.0
NODE_GYP_VERSION=	7.1.2

USES=		python:build

USE_GITHUB=	nodefault
GH_TUPLE=	nodejs:node-gyp:${NODE_GYP_VERSION}

MAKE_ENV+=	DISTDIR="${DISTDIR}"
MAKE_ENV+=	NODEJS_VERSION="${NODEJS_VERSION}"
MAKE_ENV+=	PYTHON="${PYTHON_CMD}"
MAKE_ENV+=	_DEVDIR="${_DEVDIR}"

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
