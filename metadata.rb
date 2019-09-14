name 'webapp'
maintainer 'Steve Brown'
maintainer_email 'sbrown@chef.io'
license 'Apache-2.0'
description 'Installs/Configures webapp'
long_description 'Installs/Configures webapp'
version '0.1.4'
chef_version '>= 13.6.4'

%w(windows).each do |os|
  supports os
end

depends 'iis'

issues_url 'https://github.com/devoptimist/webapp/issues'
source_url 'https://github.com/devoptimist/webapp'
