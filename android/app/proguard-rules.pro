# Some transitive libraries reference SLF4J binders that are optional at runtime.
# Ignore that optional binder class to prevent R8 release failures.
-dontwarn org.slf4j.impl.StaticLoggerBinder
