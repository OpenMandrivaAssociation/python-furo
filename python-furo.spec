# Created by pyp2rpm-3.3.5
%global pypi_name furo

Name:           python-%{pypi_name}
Version:        2020.12.30
Release:        1
Summary:        A clean customisable Sphinx documentation theme
Group:          Development/Python
License:        None
URL:            https://github.com/pradyunsg/furo
Source0:        %{pypi_name}-%{version}b24.tar.gz
BuildArch:      noarch

BuildRequires:  python3-devel
BuildRequires:  python3dist(setuptools)

%description


%prep
%autosetup -n %{pypi_name}-%{version}b24

%build
%py3_build

%install
%py3_install

%files -n python-%{pypi_name}
%license LICENSE
%doc README.md
%{python3_sitelib}/%{pypi_name}
%{python3_sitelib}/%{pypi_name}-%{version}b24-py%{python3_version}.egg-info
