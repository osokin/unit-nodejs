# Created by: Sergey Osokin <osa@FreeBSD.org>
# $FreeBSD$

MASTER_SITES=	https://unit.nginx.org/download/:unit \
		https://codeload.github.com/nodejs/node-gyp/tar.gz/v${NODE_GYP_VERSION}?dummy=/:node_gyp
PKGNAMESUFFIX=	-${UNIT_MODNAME}
DISTFILES=	unit-${UNIT_VERSION}${EXTRACT_SUFX}:unit \
		node-gyp-${NODE_GYP_VERSION}${EXTRACT_SUFX}:node_gyp

DISTINFO_FILE=	${.CURDIR}/distinfo
PATCHDIR=	${.CURDIR}/files

COMMENT=	NodeJS module for NGINX Unit

UNIT_MODNAME=	nodejs

BUILD_DEPENDS=	${LOCALBASE}/lib/libunit.a:devel/libunit \
		node:www/node \
		npm:www/npm
RUN_DEPENDS=	unitd:www/unit

UNIT_VERSION=		1.22.0
NODE_GYP_VERSION=	7.1.2

USES=		python:3.6+

MAKE_ENV+=	DISTDIR="${DISTDIR}"
MAKE_ENV+=	NODEJS_VERSION="${NODEJS_VERSION}"
MAKE_ENV+=	PYTHON="${PYTHON_CMD}"
MAKE_ENV+=	_DEVDIR="${_DEVDIR}"

USE_RC_SUBR?=	# reset to empty

MASTERDIR=	${.CURDIR}/../unit

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

pre-configure:
	(_NODEVER=$$(${_NODECMD} | ${SED} -n 's|^v\(.*\)|\1|p') && \
	${MKDIR} ${_DEVDIR}/$${_NODEVER}/include && \
	${RLN} ${LOCALBASE}/include/node ${_DEVDIR}/$${_NODEVER}/include/node && \
	${ECHO} "9" > ${_DEVDIR}/$${_NODEVER}/installVersion \
	)

post-configure:
	@cd ${CONFIGURE_WRKSRC} && \
	${SETENV} ${MAKE_ENV} ${CONFIGURE_CMD} nodejs \
		--node-gyp=${_DEVDIR}/bin/node-gyp \
		--local=${STAGEDIR}${PREFIX}/lib/node_modules/unit-http

do-build:
	@cd ${CONFIGURE_WRKSRC} && ${SETENV} ${MAKE_ENV} ${MAKE} node

do-install:
	@cd ${CONFIGURE_WRKSRC} && ${SETENV} ${MAKE_ENV} ${MAKE} node-local-install

.include "${MASTERDIR}/Makefile"