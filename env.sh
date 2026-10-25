_testilm_env_file=${BASH_SOURCE[0]}
export TESTILM_ROOT="$(cd -- "$(dirname -- "$_testilm_env_file")" && pwd)"
unset _testilm_env_file
