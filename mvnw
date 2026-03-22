#!/bin/sh
# -----------------------------------------------------------------------------
# Maven Start Up Batch script
# -----------------------------------------------------------------------------

# OS specific support
native_path() { printf %s\\n "$1"; }
case "$(uname)" in
  CYGWIN*|MINGW*|MSYS*)
    [ -z "${JAVA_HOME-}" ] || JAVA_HOME="$(native_path "$JAVA_HOME")"
    ;;
esac

# Find java
if [ -n "$JAVA_HOME" ] ; then
  if [ -x "$JAVA_HOME/jre/sh/java" ] ; then
    JAVACMD="$JAVA_HOME/jre/sh/java"
  else
    JAVACMD="$JAVA_HOME/bin/java"
  fi
else
  JAVACMD="$(\unset -f command 2>/dev/null; \command -v java)"
fi

if [ ! -x "$JAVACMD" ] ; then
  echo "Error: JAVA_HOME is not defined correctly." >&2
  exit 1
fi

# Find project base dir
MAVEN_PROJECTBASEDIR="${MAVEN_BASEDIR:-$PWD}"
export MAVEN_PROJECTBASEDIR

# Download maven if needed
MAVEN_VERSION="3.9.4"
MAVEN_HOME="$MAVEN_PROJECTBASEDIR/.mvn/wrapper/maven-$MAVEN_VERSION"
MAVEN_WRAPPER_JAR="$MAVEN_PROJECTBASEDIR/.mvn/wrapper/maven-wrapper.jar"

if [ ! -f "$MAVEN_WRAPPER_JAR" ]; then
  mkdir -p "$MAVEN_PROJECTBASEDIR/.mvn/wrapper"
  curl -o "$MAVEN_WRAPPER_JAR" -L "https://repo.maven.apache.org/maven2/org/apache/maven/wrapper/maven-wrapper/3.2.0/maven-wrapper-3.2.0.jar" 2>/dev/null || wget -q -O "$MAVEN_WRAPPER_JAR" "https://repo.maven.apache.org/maven2/org/apache/maven/wrapper/maven-wrapper/3.2.0/maven-wrapper-3.2.0.jar"
fi

exec "$JAVACMD" -classpath "$MAVEN_WRAPPER_JAR" org.apache.maven.wrapper.MavenWrapperMain "$@"
