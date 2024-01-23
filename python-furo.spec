%global pypi_name furo

Name:           python-%{pypi_name}
Version:        2023.9.10
Release:        1
Summary:        A clean customisable Sphinx documentation theme
Group:          Development/Python
License:        MIT
URL:            https://github.com/pradyunsg/furo
Source0:        https://github.com/pradyunsg/furo/archive/%{version}/furo-%{version}.tar.gz
#Source0:        https://files.pythonhosted.org/packages/source/f/furo/furo-%{version}.tar.gz
# Generated with ./prepare_vendor.sh
Source1:	furo-%{version}-vendor.tar.xz
BuildArch:      noarch

BuildRequires:  python
BuildRequires:	python%{pyver}dist(pip)
BuildRequires:	python%{pyver}dist(sphinx-theme-builder)
BuildRequires:	python%{pyver}dist(nodeenv)
BuildRequires:	nodejs

%description
A clean customisable Sphinx documentation theme

%prep
%autosetup -n %{pypi_name}-%{version} -a1
sed -i -e "s,^node-version =.*,node-version = \"$(rpm -q --qf '%%{VERSION}' nodejs)\"," pyproject.toml

%build
export YARN_CACHE_FOLDER="$(pwd)/.package-cache"
yarn install --offline
nodeenv --node=system --prebuilt --clean-src "$(pwd)/.nodeenv"
%py3_build

%install
%py3_install

%files -n python-%{pypi_name}
%license LICENSE
%doc README.md
%{python3_sitelib}/%{pypi_name}
%{python3_sitelib}/%{pypi_name}*.*-info
