mkdir -p TestResults
{ sw_vers; xcodebuild -version; swift --version; } > TestResults/toolchain.log
bash Scripts/install_xcodegen.sh
