echo Build of ILM CORE

echo Cleaning containers
docker rm ilmcont
docker rmi prebuild

echo Refreshing directory for data from container
if exist data rmdir /s /q data
mkdir data

echo PreBuild build
docker build --build-arg SERVER_USERNAME=%SERVER_USERNAME% --build-arg SERVER_PASSWORD=%SERVER_PASSWORD% -f %DOCKERFILE_PATH%-pre -t prebuild .
if errorlevel 1 exit /b 1

echo MVN Build

REM Construct optional arguments
set MAVEN_VOLUME_ARG=
set SKIP_TESTS_ARG=
set TESTCONTAINERS_ARG=

if defined MAVEN_DIR (
  set MAVEN_VOLUME_ARG=-v %MAVEN_DIR%:/root/.m2
  echo Maven directory detected: %MAVEN_DIR%
)

if defined TESTCONTAINERS_RYUK_DISABLED (
  set TESTCONTAINERS_ARG=-e TESTCONTAINERS_RYUK_DISABLED=%TESTCONTAINERS_RYUK_DISABLED%
)

if "%SKIP_TESTS%"=="true" (
  set SKIP_TESTS_ARG=-DskipTests
  echo Skipping tests as SKIP_TESTS is true
) else (
  echo Running tests as SKIP_TESTS is not true or unset (default: false)
)

docker run -v //var/run/docker.sock:/var/run/docker.sock ^
  %MAVEN_VOLUME_ARG% ^
  %TESTCONTAINERS_ARG% ^
  --name ilmcont -i prebuild ^
  mvn -f /home/app/pom.xml clean package %SKIP_TESTS_ARG%
if errorlevel 1 exit /b 1

echo Copy jar back to Tmp
docker cp ilmcont:/home/app/target data\target
if errorlevel 1 exit /b 1
docker cp ilmcont:/home/app/docker data\docker
if errorlevel 1 exit /b 1

echo Removing previous image
docker rmi %IMAGE_NAME%

echo Build main image
docker build --platform linux/amd64 -f %DOCKERFILE_PATH% -t %IMAGE_NAME% .
if errorlevel 1 exit /b 1

echo Cleaning workspace
rmdir /s /q data
