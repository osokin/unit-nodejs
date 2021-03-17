# Created by: Sergey Osokin <osa@FreeBSD.org>
# $FreeBSD$

MASTER_SITES=	https://unit.nginx.org/download/:unit
PKGNAMESUFFIX=	-${UNIT_MODNAME}
DISTFILES=	unit-${UNIT_VERSION}.tar.gz:unit

DISTINFO_FILE=	${.CURDIR}/distinfo
PATCHDIR=	${.CURDIR}/files

COMMENT=	NodeJS module for NGINX Unit

UNIT_MODNAME=	nodejs

BUILD_DEPENDS=	${LOCALBASE}/lib/libunit.a:devel/libunit \
		node:www/node \
		node-gyp:devel/node-gyp \
		npm:www/npm
RUN_DEPENDS=	unitd:www/unit

UNIT_VERSION=	1.22.0

USES=		python:3.6+

MAKE_ENV+=	DISTDIR="${DISTDIR}"
MAKE_ENV+=	NODEJS_VERSION="${NODEJS_VERSION}"
MAKE_ENV+=	PYTHON="${PYTHON_CMD}"
MAKE_ENV+=	_DEVDIR="${_DEVDIR}"

USE_RC_SUBR?=	# reset to empty

MASTERDIR=	${.CURDIR}/../unit

PLIST_FILES=	lib/node_modules/unit-http/addon.cpp \
		lib/node_modules/unit-http/binding_pub.gyp \
		lib/node_modules/unit-http/binding.gyp \
		lib/node_modules/unit-http/http_server.js \
		lib/node_modules/unit-http/http.js \
		lib/node_modules/unit-http/nxt_napi.h \
		lib/node_modules/unit-http/package.json \
		lib/node_modules/unit-http/README.md \
		lib/node_modules/unit-http/socket.js \
		lib/node_modules/unit-http/unit.cpp \
		lib/node_modules/unit-http/unit.h \
		lib/node_modules/unit-http/utils.js \
		lib/node_modules/unit-http/version.h \
		lib/node_modules/unit-http/websocket_connection.js \
		lib/node_modules/unit-http/websocket_frame.js \
		lib/node_modules/unit-http/websocket_request.js \
		lib/node_modules/unit-http/websocket_router_request.js \
		lib/node_modules/unit-http/websocket_router.js \
		lib/node_modules/unit-http/websocket_server.js \
		lib/node_modules/unit-http/websocket.js \
		lib/node_modules/unit-http/build/Release/unit-http.node \
		lib/node_modules/unit-http/build/Release/obj.target/unit-http.node

_NODECMD=	${LOCALBASE}/bin/node --version
_DEVDIR:=	${WRKDIR}/.devdir

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
		--node-gyp=${LOCALBASE}/bin/node-gyp \
		--local=${STAGEDIR}${PREFIX}/lib/node_modules/unit-http

do-build:
	@cd ${CONFIGURE_WRKSRC} && ${SETENV} ${MAKE_ENV} ${MAKE} node

do-install:
	@cd ${CONFIGURE_WRKSRC} && ${SETENV} ${MAKE_ENV} ${MAKE} node-local-install

.include "${MASTERDIR}/Makefile"
