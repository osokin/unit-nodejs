--- src/nodejs/unit-http/binding.gyp.orig	2021-03-10 13:58:22.190304000 -0500
+++ src/nodejs/unit-http/binding.gyp	2021-03-10 13:59:53.258512000 -0500
@@ -12,10 +12,10 @@
         ],
         'sources': ["unit.cpp", "addon.cpp"],
         'include_dirs': [
-            "<!(echo $UNIT_SRC_PATH)", "<!(echo $UNIT_BUILD_PATH)"
+            "/usr/include", "%%PREFIX%%/include"
         ],
         'libraries': [
-            "<!(echo $UNIT_LIB_STATIC_PATH)"
+            "%%PREFIX%%/lib/libunit.a"
         ]
     }]
 }
