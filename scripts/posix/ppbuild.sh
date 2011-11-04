# !/bin/bash
home=/home/$USER
buildpsi=${home}/psi
orig_src=${buildpsi}/build
patches=${buildpsi}/git-plus/patches
psi_datadir=${home}/.local/share/Psi+
psi_cachedir=${home}/.cache/Psi+
psi_homeplugdir=${psi_datadir}/plugins
config_file=${home}/.psibuild.cfg
inst_suffix=tmp
inst_path=${buildpsi}/${inst_suffix}
isloop=1
# default options
iswebkit=""
use_iconsets="system clients activities moods affiliations roster"
isoffline=0
skip_invalid=0
use_plugins="*"
#
qconfspath ()
{
  if [ ! -f "/usr/bin/qconf" ]
  then
    if [ ! -f "/usr/local/bin/qconf" ]
      then
        echo "Enter the path to qconf directory (Example: /home/me/qconf):"
        read qconfpath
    fi
  fi
}
#
quit ()
{
  isloop=0
}
#
read_options ()
{
  local pluginlist=""
  if [ -f ${config_file} ]
  then
    inc=0
    while read -r line
    do
      case ${inc} in
      "0" ) iswebkit=`echo ${line}`;;
      "1" ) use_iconsets=`echo ${line}`;;
      "2" ) isoffline=`echo ${line}`;;
      "3" ) skip_invalid=`echo ${line}`;;
      "4" ) pluginlist=`echo ${line}`;;
      esac
      let "inc+=1"
    done < ${config_file}
    if [ "$pluginlist" == "all" ]
    then
      use_plugins="*"
    else
      use_plugins=${pluginlist}
    fi
  fi

}
#
set_options ()
{
  # OPTIONS / НАСТРОЙКИ
  # build and store directory / каталог для сорсов и сборки
  PSI_DIR="${buildpsi}" # leave empty for ${HOME}/psi on *nix or /c/psi on windows
  # icons for downloads / иконки для скачивания
  ICONSETS=${use_iconsets}
  # do not update anything from repositories until required
  # не обновлять ничего из репозиториев если нет необходимости
  WORK_OFFLINE=${WORK_OFFLINE:-$isoffline}
  # log of applying patches / лог применения патчей
  PATCH_LOG="" # PSI_DIR/psipatch.log by default (empty for default)
  # skip patches which applies with errors / пропускать глючные патчи
  SKIP_INVALID_PATCH="${SKIP_INVALID_PATCH:-$skip_invalid}"
  # configure options / опции скрипта configure
  CONF_OPTS=${iswebkit}
  # install root / каталог куда устанавливать (полезно для пакаджеров)
  INSTALL_ROOT="${INSTALL_ROOT:-$inst_path}"
  # bin directory of compiler cache (all compiler wrappers are there)
  CCACHE_BIN_DIR="${CCACHE_BIN_DIR}"
  # if system doesn't have qconf package set this variable to
  # manually compiled qconf directory.
  QCONFDIR="${QCONFDIR}"
  # plugins to build
  PLUGINS="${PLUGINS:-$use_plugins}"
}
#
check_libpsibuild ()
{
  # checkout libpsibuild
  cd ${home}
  die() { echo "$@"; exit 1; }
  if [ ! -f ./libpsibuild.sh -o "$WORK_OFFLINE" = 0 ]
  then
    [ -f libpsibuild.sh ] && { rm libpsibuild.sh || die "delete error"; }
    wget --no-check-certificate "https://raw.github.com/psi-plus/maintenance/master/scripts/posix/libpsibuild.sh" || die "Failed to update libpsibuild";
  fi
}
#
run_libpsibuild ()
{
  if [ ! -z "$1" ]
  then
    cmd=$1
    cd ${home}
    . ./libpsibuild.sh
    check_env $CONF_OPTS
    $cmd
  fi
}
#
down_all ()
{
  echo "Downloading all psi+ sources needed to build"
  run_libpsibuild fetch_all
}
#
prepare_src ()
{
  echo "Downloading and preparing psi+ sources needed to build"
  run_libpsibuild validate_plugins_list
  run_libpsibuild fetch_all
  run_libpsibuild prepare_all
}
#
backup_tar ()
{
  cd ${home}
  tar -pczf psi.tar.gz psi
}
#
restore_tar ()
{
  cd ${home}
  if [ -f "psi.tar.gz" ]
  then
    if [ -d ${buildpsi} ]
    then
       rm -r -f ${buildpsi}
    fi
    tar -xzf psi.tar.gz
  fi
}
#
back_restore()
{
  local loop=1
  while [ ${loop} = 1 ]
  do
    echo "Choose action TODO:"
    echo "--[1] - Backup sources to tar.gz"
    echo "--[2] - Restore sources from tar.gz"
    echo "--[0] - Do nothing"
    read deistvo
    case ${deistvo} in
      "1" ) backup_tar;;
      "2" ) restore_tar;;
      "0" ) clear
            loop=0;;
    esac
  done
}
#
prepare_tar ()
{
  echo "Preparing Psi+ source package to build RPM..."
  rev=$(cd ${buildpsi}/git-plus/; echo $((`git describe --tags | cut -d - -f 2`+5000)))
  tar_name=psi-plus-0.15.${rev}
  new_src=${buildpsi}/${tar_name}
  local srcpath=/usr/src/packages/SOURCES
  cp -r ${orig_src} ${new_src}
  if [ -d ${new_src} ]
  then
    cd ${buildpsi}
    tar -pczf ${tar_name}.tar.gz ${tar_name}
    rm -r -f ${new_src}
    if [ -d ${srcpath} ]
    then
      if [ ! -f "${srcpath}/${tar_name}.tar.gz" ]
      then
        cp -u ${buildpsi}/${tar_name}.tar.gz ${srcpath}
      fi
    fi
    echo "Preparing completed"
  fi
}
#
prepare_win ()
{
  echo "Preparing Psi+ source package to build in OS Windows..."
  prepare_src
  rev=$(cd ${buildpsi}/git-plus/; echo $((`git describe --tags | cut -d - -f 2`+5000)))
  tar_name=psi-plus-0.15.${rev}-win
  new_src=${buildpsi}/${tar_name}
  local winpri=${new_src}/conf_windows.pri
  local mainicon=${buildpsi}/git-plus/app.ico
  local file_pro=${new_src}/src/src.pro
  local ossl=${new_src}/third-party/qca/qca-ossl.pri
  cp -r ${orig_src} ${new_src}
  if [ -d ${new_src} ]
  then
    cd ${buildpsi}
    sed "s/#CONFIG += qca-static/CONFIG += qca-static\nCONFIG += webkit/" -i "${winpri}"
    sed "s/#DEFINES += HAVE_ASPELL/DEFINES += HAVE_ASPELL/" -i "${winpri}"
    sed "s/LIBS += -lgdi32 -lwsock32/LIBS += -lgdi32 -lwsock32 -leay32/" -i "${ossl}"
    sed "s/#CONFIG += psi_plugins/CONFIG += psi_plugins/" -i "${file_pro}"
    cp -f ${mainicon} ${new_src}/win32/
    makepsi='qconf
configure --enable-plugins --enable-whiteboarding --qtdir=%QTDIR% --with-openssl-inc=%OPENSSLDIR%\include --with-openssl-lib=%OPENSSLDIR%\lib\MinGW --disable-xss --disable-qdbus --with-aspell-inc=%MINGWDIR%\include --with-aspell-lib=%MINGWDIR%\lib
@echo ================================
@echo Compiler is ready for fight! B-)
@echo ================================
pause
mingw32-make
pause
move /Y src\release\psi-plus.exe ..\psi-plus.exe
pause
compile-plugins -o ..\
pause
@goto exit

:exit
pause'
    makewebkitpsi='qconf
configure --enable-plugins --enable-whiteboarding --enable-webkit --qtdir=%QTDIR% --with-openssl-inc=%OPENSSLDIR%\include --with-openssl-lib=%OPENSSLDIR%\lib\MinGW --disable-xss --disable-qdbus --with-aspell-inc=%MINGWDIR%\include --with-aspell-lib=%MINGWDIR%\lib
@echo ================================
@echo Compiler is ready for fight! B-)
@echo ================================
pause
mingw32-make
pause
move /Y src\release\psi-plus.exe ..\psi-plus.exe
pause
compile-plugins -o ..\
pause
@goto exit

:exit
pause'
    echo "${makepsi}" > ${new_src}/make-psiplus.cmd
    echo "${makewebkitpsi}" > ${new_src}/make-webkit-psiplus.cmd
    tar -pczf ${tar_name}.tar.gz ${tar_name}
    rm -r -f ${new_src}
  fi
}
#
compile_psiplus ()
{
  set_options
  run_libpsibuild prepare_workspace
  prepare_src
  run_libpsibuild compile_psi
}
#
build_plugins ()
{
  cd ${buildpsi}
  if [ ! -d ${inst_path} ]
  then
    mkdir ${inst_suffix}
  fi
  prepare_src
  run_libpsibuild compile_plugins
  run_libpsibuild install_plugins
  if [ ! -d ${psi_homeplugdir} ]
  then
    cd ${psi_datadir}
    mkdir plugins
  fi
  cp ${inst_path}/usr/lib/psi-plus/plugins/* ${psi_homeplugdir}
  rm -rf ${inst_path}
  cd ${home}
}
#
build_deb_package ()
{
    echo "Building Psi+ DEB package with checkinstall"
    cd ${patches}
    rev=$(cd ${buildpsi}/git-plus/; echo $((`git describe --tags | cut -d - -f 2`+5000)))
    desc='Psi is a cross-platform powerful Jabber client (Qt, C++) designed for the Jabber power users.
Psi+ - Psi IM Mod by psi-dev@conference.jabber.ru.'
    cd ${orig_src}
    echo "${desc}" > description-pak
    requires=' "libaspell15 (>=0.60)", "libc6 (>=2.7-1)", "libgcc1 (>=1:4.1.1)", "libqca2", "libqt4-dbus (>=4.4.3)", "libqt4-network (>=4.4.3)", "libqt4-qt3support (>=4.4.3)", "libqt4-xml (>=4.4.3)", "libqtcore4 (>=4.4.3)", "libqtgui4 (>=4.4.3)", "libstdc++6 (>=4.1.1)", "libx11-6", "libxext6", "libxss1", "zlib1g (>=1:1.1.4)" '
    sudo checkinstall -D --nodoc --pkgname=psi-plus --pkggroup=net --pkgversion=0.15.${rev} --pkgsource=${orig_src} --maintainer="thetvg@gmail.com" --requires="${requires}"
    cp -f ${orig_src}/*.deb ${buildpsi}
}
#
prepare_spec ()
{
  echo "Creating psi.spec file..."
  specfile='Summary: Client application for the Jabber network
Name: psi-plus
Version: 0.15.xxxx
Release: 1
License: GPL
Group: Applications/Internet
URL: http://code.google.com/p/psi-dev/
Source0: %{name}-%{version}.tar.gz


BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root


BuildRequires: openssl-devel, gcc-c++, zlib-devel
%{!?_without_freedesktop:BuildRequires: desktop-file-utils}


%description
Psi is the premiere Instant Messaging application designed for Microsoft Windows, 
Apple Mac OS X and GNU/Linux. Built upon an open protocol named Jabber,           
si is a fast and lightweight messaging client that utilises the best in open      
source technologies. The goal of the Psi project is to create a powerful, yet     
easy-to-use Jabber/XMPP client that tries to strictly adhere to the XMPP drafts.  
and Jabber JEPs. This means that in most cases, Psi will not implement a feature  
unless there is an accepted standard for it in the Jabber community. Doing so     
ensures that Psi will be compatible, stable, and predictable, both from an end-user 
and developer standpoint.
Psi+ - Psi IM Mod by psi-dev@conference.jabber.ru


%prep
%setup


%build
qconf
./configure --prefix="%{_prefix}" --bindir="%{_bindir}" --datadir="%{_datadir}" --qtdir=$QTDIR --enable-plugins --enable-webkit
%{__make} %{?_smp_mflags}


%install
%{__rm} -rf %{buildroot}


%{__make} install INSTALL_ROOT="%{buildroot}"


# Install the pixmap for the menu entry
%{__install} -Dp -m0644 iconsets/system/default/logo_128.png \
    %{buildroot}%{_datadir}/pixmaps/psi-plus.png ||:               


%post
touch --no-create %{_datadir}/icons/hicolor || :
%{_bindir}/gtk-update-icon-cache --quiet %{_datadir}/icons/hicolor || :


%postun
touch --no-create %{_datadir}/icons/hicolor || :
%{_bindir}/gtk-update-icon-cache --quiet %{_datadir}/icons/hicolor || :


%clean
%{__rm} -rf %{buildroot}


%files
%defattr(-, root, root, 0755)
%doc COPYING README TODO
%{_bindir}/psi-plus
%{_bindir}/psi-plus.debug
%{_datadir}/psi-plus/
%{_datadir}/pixmaps/psi-plus.png
%{_datadir}/applications/psi-plus.desktop
%{_datadir}/icons/hicolor/*/apps/psi-plus.png
%exclude %{_datadir}/psi-plus/COPYING
%exclude %{_datadir}/psi-plus/README
'
  tmp_spec=${buildpsi}/test.spec
  usr_spec="/usr/src/packages/SPECS/psi-plus.spec"
  echo "${specfile}" > ${tmp_spec}
  if [ ! -d "/usr/src/packages/SPECS" ]
  then
    usr_spec=${buildpsi}/psi-plus.spec
  fi
  cp -f ${tmp_spec} ${usr_spec}
}
#
set_spec_ver ()
{ 
  echo "Parsing svn revision to psi-plus.spec"
  if [ -f ${usr_spec} ]
  then
    rev=$(cd ${buildpsi}/git-plus/; echo $((`git describe --tags | cut -d - -f 2`+5000)))
    vers="0.15.${rev}"
    sed "s/0\.15\.\xxxx/${vers}/" -i "${usr_spec}"
    if [ -z ${iswebkit} ]
    then
      sed "s/--enable-webkit/ /" -i "${usr_spec}"
    fi
    qconfspath
    if [ ${qconfpath} ]
    then
      local qconfcmd=${qconfpath}/qconf
      sed "s/qconf/${qconfcmd}/" -i "${usr_spec}"
    fi
  fi
}
#
build_rpm_package ()
{
  rev=$(cd ${buildpsi}/git-plus/; echo $((`git describe --tags | cut -d - -f 2`+5000)))
  tar_name=psi-plus-0.15.${rev}
  sources=/usr/src/packages/SOURCES
  if [ -f "${sources}/${tar_name}.tar.gz" ]
  then
    prepare_spec
    set_spec_ver
    echo "Building Psi+ RPM package"
    if [ -f "/usr/src/packages/SPECS/psi-plus.spec" ]
    then
      specpath=/usr/src/packages/SPECS
    else
      specpath=${buildpsi}
    fi
    cd ${specpath}
    echo "Do yo want to sign this package by your gpg-key [y/n]"
    read otvet
    if [ ${otvet} = "y" ]
    then
      if [ -f "${home}/.rpmmacros" ]
      then
        rpmbuild -ba --clean --sign --rmspec --rmsource ${usr_spec}
      else
        local mess='Make sure that you have the .rpmmacros file in $HOME directory

---Exaple of .rpmmacros contents---

   %_signature    gpg
   %_gpg_name     uid
   %_gpg_path     /home/$USER/.gnupg
   %packager      UserName <user_email>

--- End ---

uid and path you can get by running command:
   gpg --list-keys

---Try again later---'
        echo "${mess}"
      fi
    else
      rpmbuild -ba --clean --sign --rmspec --rmsource ${usr_spec}
    fi
  fi
}
#
prepare_dev ()
{
psidev=$buildpsi/psidev
orig=$psidev/git.orig
new=$psidev/git
rm -rf $orig
rm -rf $new
cd ${buildpsi}
echo ${psidev}
if [ ! -d ${psidev} ]
then
  mkdir $psidev
fi
if [ ! -d ${orig} ]
then
  mkdir $orig
fi
if [ ! -d ${new} ]
then
  mkdir $new
fi
cp -r git/* ${orig}
cp -r git/* ${new}
cd ${psidev}
if [ ! -f deploy ]
then
  wget --no-check-certificate "https://raw.github.com/psi-plus/maintenance/master/scripts/posix/deploy" || die "Failed to update deploy";
fi
if [ ! -f mkpatch ]
then
  wget --no-check-certificate "https://raw.github.com/psi-plus/maintenance/master/scripts/posix/mkpatch" || die "Failed to update mkpatch";
fi
if [ ! -f psidiff.ignore ]
then
  wget --no-check-certificate "https://raw.github.com/psi-plus/maintenance/master/scripts/posix/psidiff.ignore" || die "Failed to update psidiff.ignore";
fi
patchlist=`ls ${buildpsi}/git-plus/patches/ | grep diff`
cd ${orig}
echo "Enter maximum patch number to patch orig src"
read patchnumber
for patchfile in ${patchlist}
  do
    if [  ${patchfile:0:4} -lt ${patchnumber} ]
    then
      echo  ${patchfile}
      patch -p1 < ${buildpsi}/git-plus/patches/${patchfile}
    fi
done
cd ${new}
echo "Enter maximum patch number to patch work src"
read patchnumber
for patchfile in ${patchlist}
  do
    if [  ${patchfile:0:4} -lt ${patchnumber} ]
    then
      echo  ${patchfile}
      patch -p1 < ${buildpsi}/git-plus/patches/${patchfile}
    fi
done
}
#
set_config ()
{
  local use_webkit="n"
  if [ ! -z "$iswebkit" ]
  then
    use_webkit="y"
  else
    use_webkit="n"
  fi
  local is_offline="n"
  if [ "$isoffline" -eq 0 ]
  then
    is_offline="n"
  else
    is_offline="y"
  fi
  local skip_patches="n"
  if [ "$skip_invalid" -eq 0 ]
  then
    skip_patches="n"
  else
    skip_patches="y"
  fi
  local loop=1
  while [ ${loop} = 1 ]
  do
    echo "Choose action TODO:"
    echo "--[1] - Set WebKit version to use (current: ${use_webkit})"
    echo "--[2] - Set iconsets list needed to build"
    echo "--[3] - Set Offline Mode (current: ${is_offline})"
    echo "--[4] - Skip Invalid patches (current: ${skip_patches})"
    echo "--[5] - Set list of plugins needed to build (for all use *)"
    echo "--[6] - Print option values"
    echo "--[0] - Do nothing"
    read deistvo
    case ${deistvo} in
      "1" ) echo "Do you want use WebKit [y/n] ?"
            read variable
            if [ "$variable" == "y" ]
            then
              iswebkit="--enable-webkit"
              use_webkit="y"
            else
              iswebkit=""
              use_webkit="n"
            fi;;
      "2" ) echo "Please enter iconsets separated by space"
            read variable
            if [ ! -z "$variable" ]
            then
              use_iconsets=${variable}
            else
              use_iconsets="system clients activities moods affiliations roster"
            fi;;
      "3" ) echo "Do you want use Offline Mode [y/n] ?"
            read variable
            if [ "$variable" == "y" ]
            then
              isoffline=1
              is_offline="y"
            else
              isoffline=0
              is_offline="n"
            fi;;
      "4" ) echo "Do you want to skip invalid patches when patching [y/n] ?"
            read variable
            if [ "$variable" == "y" ]
            then
              skip_invalid=1
              skip_patches="y"
            else
              skip_invalid=0
              skip_patches="n"
            fi;;
      "5" ) echo "Please enter plugins needed to build separated by space (* for all)"
            read variable
            if [ ! -z "$variable" ]
            then
              use_plugins=${variable}
            else
              use_plugins=""
            fi;;
      "6" ) echo "==Options=="
            echo "WebKit = ${use_webkit}"
            echo "Iconsets = ${use_iconsets}"
            echo "Offline Mode = ${is_offline}"
            echo "Skip Invalid Patches = ${skip_patches}"
            echo "Plugins = ${use_plugins}"
            echo "===========";;
      "0" ) clear
            loop=0;;
    esac
  done
  echo "$iswebkit" > ${config_file}
  echo "$use_iconsets" >> ${config_file}
  echo "$isoffline" >> ${config_file}
  echo "$skip_invalid" >> ${config_file}
  if [ "$use_plugins" == "*" ]
  then
    echo "all" >> ${config_file}
  else
    echo "$use_plugins" >> ${config_file}
  fi
}
#
print_menu ()
{
  local menu_text='Choose action TODO!
[1] - Download All needed source files to build psi+
---[11] - Backup/Restore sources to/from tar.gz
[2] - Prepare psi+ sources
---[21] - Prepare psi+ source package to build in OS Windows
[3] - Build psi+ binary
---[31] - Build and install psi+ plugins
[4] - Build Debian package with checkinstall
[5] - Build openSUSE RPM-package
[6] - Set libpsibuild options
[7] - Prepare psi+ sources for development
[9] - Get help on additional actions
[0] - Exit'
  echo "${menu_text}"
}
#
get_help ()
{
echo "---------------HELP-----------------------"
echo "[u] - update and backup sources into tar.gz"
echo "[up] - Download all sources and build psi+ binary"
echo "-------------------------------------------"
echo "Press Enter to continue..."
read
}
#
choose_action ()
{
  read vibor
  case ${vibor} in
    "1" ) down_all;;
    "11" ) back_restore;;
    "2" ) prepare_src;;
    "21" ) prepare_win;;
    "3" ) compile_psiplus;;
    "31" ) build_plugins;;
    "4" ) build_deb_package;;
    "5" ) prepare_tar
              build_rpm_package;;
    "6" ) set_config;;
    "7" ) prepare_dev;;
    "9" ) get_help;;
    "u" ) restore_tar
              backup_tar;;
    "up" ) prepare_src
              compile_psiplus;;
    "0" ) quit;;
  esac
}
#
cd ${home}
check_libpsibuild
if [ ! -d "${buildpsi}" ]
then
  set_config
fi
read_options
set_options
run_libpsibuild prepare_workspace
clear
#
while [ ${isloop} = 1 ]
do
  print_menu
  choose_action
done
exit 0
