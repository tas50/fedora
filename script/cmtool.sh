#!/bin/bash -eux

# CM and CM_VERSION variables should be set inside of Packer's template:
#
# Values for CM are:
#   'nocm'            -- build a box without a configuration management tool
#   'chef'            -- build a box with the Chef
#   'chefdk'          -- build a box with the Chef Development Kit
#   'salt'            -- build a box with the Salt 
#   'puppet'          -- build a box with the Puppet
#
# Values for CM_VERSION can be (when CM is chef|salt|puppet):
#   'x.y.z'           -- build a box with version x.y.z of Chef
#   'x.y'             -- build a box with version x.y of Salt
#   'latest'          -- build a box with the latest version
#
# Set CM_VERSION to 'latest' if unset because it can be problematic
# to set variables in pairs with Packer (and Packer does not support
# multi-value variables).
CM_VERSION=${CM_VERSION:-latest}

#
# CM installs.
#

install_chef()
{
    echo "==> Installing Chef provisioner"
    if [[ ${CM_VERSION:-} == 'latest' ]]; then
        echo "==> Installing latest Chef version"
        curl -Lk https://www.opscode.com/chef/install.sh | sh
    else
        echo "==> Installing Chef version ${CM_VERSION}"
        curl -Lk https://www.opscode.com/chef/install.sh | sh -s -- -v ${CM_VERSION}
    fi
}

install_chefdk()
{
    echo "==> Installing Chef Development Kit"
    if [[ ${CM_VERSION:-} == 'latest' ]]; then
        echo "==> Installing latest Chef version"
        curl -Lk https://www.opscode.com/chef/install.sh | sh -s -- -P chefdk
    else
        echo "==> Installing Chef version ${CM_VERSION}"
        curl -Lk https://www.opscode.com/chef/install.sh | sh -s -- -P chefdk -v ${CM_VERSION}
    fi
    echo "==> Adding Chef Development Kit and Ruby to PATH"
    echo 'eval "$(chef shell-init bash)"' >> /home/vagrant/.bash_profile
    chown vagrant /home/vagrant/.bash_profile
}

install_salt()
{
    echo "==> Installing Salt provisioner"
    if [[ ${CM_VERSION:-} == 'latest' ]]; then
        echo "==> Installing latest Salt version"
        curl -L http://bootstrap.saltstack.org | sudo sh
    else
        echo "==> Installing Salt version ${CM_VERSION}"
        curl -L http://bootstrap.saltstack.org | sudo sh -s -- git ${CM_VERSION}
    fi
}

install_puppet()
{
    echo "==> Installing Puppet provisioner"
    REDHAT_MAJOR_VERSION=$(egrep -Eo 'release ([0-9][0-9.]*)' /etc/redhat-release | cut -f2 -d' ' | cut -f1 -d.)

    echo "==> Installing Puppet Labs repositories"
    rpm -ipv "http://yum.puppetlabs.com/puppetlabs-release-fedora-${REDHAT_MAJOR_VERSION}.noarch.rpm"

    if [[ ${CM_VERSION:-} == 'latest' ]]; then
        echo "==> Installing latest Puppet version"
        ${PKG_MGR} -y install puppet
    else
        echo "==> Installing Puppet version ${CM_VERSION}"
        ${PKG_MGR} -y install "puppet-${CM_VERSION}"
    fi
}

#
# Main script
#

case "${CM}" in
  'chef')
    install_chef
    ;;

  'salt')
    install_salt
    ;;

  'puppet')
    install_puppet
    ;;

  *)
    echo "==> Building box without baking in a configuration management tool"
    ;;
esac
