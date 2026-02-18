# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )

DESCRIPTION="A simple and lightweight app for running Windows games using UMU-Launcher"
HOMEPAGE="https://github.com/Faugus/faugus-launcher"
SRC_URI="https://github.com/Faugus/${PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="gamemode mangohud"

inherit meson python-single-r1 xdg

REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="
	${PYTHON_DEPS}
	$(python_gen_cond_dep '
		>=dev-python/pygobject-3.50.1[${PYTHON_USEDEP}]
		>=dev-python/requests-2.32.5[${PYTHON_USEDEP}]
		>=dev-python/pillow-11.3.0[${PYTHON_USEDEP}]
		>=dev-python/filelock-3.20.0[${PYTHON_USEDEP}]
		>=dev-python/vdf-4.0[${PYTHON_USEDEP}]
		>=dev-python/psutil-7.1.0[${PYTHON_USEDEP}]
		>=dev-python/icoextract-0.2.0[${PYTHON_USEDEP}]
	')
	x11-libs/gtk+:3
	x11-misc/xdg-user-dirs
	media-libs/libcanberra-gtk3
	media-gfx/imagemagick
	dev-libs/libayatana-appindicator
	gamemode? ( games-util/gamemode )
	mangohud? ( games-util/mangohud )
"

src_install() {
	meson_src_install
	python_fix_shebang "${ED}"
	python_optimize
}

pkg_preinst() {
	xdg_pkg_preinst
}

pkg_postinst() {
	xdg_pkg_postinst

	elog "Faugus Launcher requires UMU-Launcher to run Windows games."
	elog "The application will download UMU-Launcher automatically on first run."
	elog ""
	elog "Optional runtime features:"
	elog "  USE=gamemode  - Enable GameMode for CPU governor optimization"
	elog "  USE=mangohud  - Enable MangoHud FPS overlay (requires GURU overlay)"
}

pkg_postrm() {
	xdg_pkg_postrm
}
