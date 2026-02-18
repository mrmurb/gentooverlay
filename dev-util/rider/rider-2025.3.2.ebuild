# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop wrapper xdg

DESCRIPTION="A cross-platform .NET IDE based on the IntelliJ platform and ReSharper."
HOMEPAGE="https://www.jetbrains.com/rider/"
SRC_URI="https://download-cf.jetbrains.com/rider/JetBrains.Rider-${PV}.tar.gz"

LICENSE="|| ( JetBrains-business JetBrains-educational JetBrains-classroom JetBrains-individual )"
LICENSE+=" 0BSD Apache-2.0 BSD BSD-2 CC0-1.0 CC-BY-2.5 CC-BY-3.0 CC-BY-4.0 CDDL-1.1 CPL-1.0 EPL-1.0 GPL-2"
LICENSE+=" GPL-2-with-classpath-exception ISC JSON LGPL-2.1 LGPL-3 LGPL-3+ libpng MIT MPL-1.1 MPL-2.0"
LICENSE+=" Ms-PL Ms-RL OFL-1.1 public-domain unicode Unlicense W3C ZLIB ZPL"

SLOT="0"
KEYWORDS="~amd64"
IUSE="wayland"

BDEPEND="dev-util/patchelf"

RDEPEND="
	dev-libs/libdbusmenu
	|| (
		dev-util/lttng-ust-compat:0/2.12
		dev-util/lttng-ust:0/2.12
	)
	llvm-core/lldb
	media-libs/mesa[X(+)]
	sys-process/audit
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXi
	x11-libs/libXrandr
"

S="${WORKDIR}/JetBrains Rider-${PV}"

# Suppress QA warnings for prebuilt binaries
# RPATH fixed in critical JBR libraries; remaining prebuilt files exempted
QA_PREBUILT="opt/${P}/*"
QA_SONAME="opt/${P}/*"

RESHARPER_DIR="lib/ReSharperHost"
PLUGIN_DIR="plugins"

src_prepare() {
	default

	# Remove unsupported architectures to reduce install size
	local remove_arches=(
		arm64
		aarch64
		macos
		windows-
		win-
	)

	for arch in "${remove_arches[@]}"; do
		einfo "Removing files for ${arch}"
		find . -name "*${arch}*" -exec rm -rf {} + 2>/dev/null || true
	done

	# Fix RPATH security issues in bundled JBR (JetBrains Runtime)
	# Removes dangerous '.' (current directory) from RPATH
	einfo "Fixing RPATH in critical JBR libraries"
	if [[ -f jbr/lib/libjcef.so ]]; then
		patchelf --set-rpath '$ORIGIN' jbr/lib/libjcef.so || die "Failed to patch libjcef.so"
	fi
	if [[ -f jbr/lib/libcef.so ]]; then
		patchelf --set-rpath '$ORIGIN' jbr/lib/libcef.so || die "Failed to patch libcef.so"
	fi
	if [[ -f jbr/lib/jcef_helper ]]; then
		patchelf --set-rpath '$ORIGIN' jbr/lib/jcef_helper || die "Failed to patch jcef_helper"
	fi

	# Enable experimental wayland support if requested
	if use wayland; then
		echo "-Dawt.toolkit.name=WLToolkit" >> bin/rider64.vmoptions || die

		elog "Experimental wayland support has been enabled"
		elog "You may need to update your JBR runtime to the latest version"
		elog "https://github.com/JetBrains/JetBrainsRuntime/releases"
	fi
}

src_install() {
	local dir="/opt/${P}"

	insinto "${dir}"
	doins -r *

	# Set executable permissions for main binaries
	fperms 755 "${dir}"/bin/{rider,fsnotifier,restarter,remote-dev-server}
	fperms 755 "${dir}"/bin/{remote-dev-server,inspect,rider,format,ltedit,jetbrains_client}.sh

	# Profiler tools
	fperms 755 "${dir}"/tools/profiler/{dotmemory,dottrace}
	fperms 755 "${dir}"/tools/profiler/{dotMemory,dotTrace}.sh

	# ReSharper backend
	fperms 755 "${dir}"/"${RESHARPER_DIR}"/linux-x64/Rider.Backend
	fperms 755 "${dir}"/"${RESHARPER_DIR}"/linux-x64/JetBrains.Debugger.Worker
	fperms 755 "${dir}"/"${RESHARPER_DIR}"/linux-x64/JetBrains.ProcessEnumerator.Worker
	fperms 755 "${dir}"/"${RESHARPER_DIR}"/linux-x64/{clang-format,jb_zip_unarchiver}
	fperms 755 "${dir}"/"${RESHARPER_DIR}"/linux-x64/dotnet/dotnet

	# Debugger components
	fperms 755 "${dir}"/"${PLUGIN_DIR}"/cidr-debugger/bin/lldb/linux/x64/bin/{lldb,lldb-server,lldb-argdumper,LLDBFrontend}
	fperms 755 "${dir}"/"${PLUGIN_DIR}"/dotCommon/DotFiles/linux-x64/JetBrains.Profiler.PdbServer
	fperms 755 "${dir}"/"${PLUGIN_DIR}"/remote-dev-server/selfcontained/bin/{xkbcomp,Xvfb}
	fperms 755 "${dir}"/"${PLUGIN_DIR}"/gateway-plugin/lib/remote-dev-workers/remote-dev-worker-linux-amd64

	# JetBrains Runtime (JBR)
	fperms 755 "${dir}"/jbr/bin/{java,javac,javadoc,jcmd,jdb,jfr,jhsdb,jinfo,jmap,jps,jrunscript,jstack,jstat,keytool,rmiregistry,serialver}
	fperms 755 "${dir}"/jbr/lib/{chrome-sandbox,cef_server,jcef_helper,jexec,jspawnhelper}

	# Create wrapper script
	make_wrapper "${PN}" "${dir}/bin/${PN}"

	# Install icons and desktop entry
	doicon -s scalable bin/"${PN}".svg
	doicon -s 128 bin/"${PN}".png
	make_desktop_entry "${PN}" "Rider ${PV}" "${PN}" "Development;IDE;" \
		"MimeType=application/x-visual-studio-solution;application/x-msbuild-project;"

	# Install MIME type definitions for .NET files
	insinto /usr/share/mime/packages
	doins "${FILESDIR}/rider-mimetypes.xml"
}

pkg_preinst() {
	xdg_pkg_preinst
}

pkg_postinst() {
	xdg_pkg_postinst
}

pkg_postrm() {
	xdg_pkg_postrm
}
