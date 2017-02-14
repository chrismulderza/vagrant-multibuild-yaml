# vagrant-multibuild-yaml
Vagrant multi-machine build with externalized YAML configuration

# Synopsis

A custom `Vagrantfile` for building multiple machines, with machine configuration
externalized as a YAML configuration file. This `Vagrantfile` has been developed to allow
testers and developers to quickly model more "traditional" multi-machine
architectures/configurations, especially for "enterprisy" software. 

Currently the `Vagrantfile` only works with the **Virtualbox** vagrant provider,
and the components have only been tested on [macOS](https://en.wikipedia.org/wiki/MacOS)
as that is what I use a my daily driver. 

**Disclaimer:** *I am not a full-time Ruby developer, and thus some (most) of
the Ruby constructs used in this `Vagrantfile` may not be the most elegant or
efficient*

The `Vagrantfile` sources a file named `build.yaml` from the current directory,
and for general use, you should only ever have to update/change this file.

The `build.yaml` file describes groups of options. Currently two option types are 
recognized: `general` which defines common options for the project and `machine`,
which is a repeatable block that defines one or more virtual machines. 

## option: general

```YAML
- option: general
  tld: dev
  domain: bitbuild
  project: bitbuild
``` 
At the moment general options configure the DNS top level domain (`tld`), a domain
(`domain`) and project name (`project`). The top level domain, and domain are 
used to configure the [macOS](https://en.wikipedia.org/wiki/MacOS) resolver, and
the domain part of the fully qualified domain name (FQDN). The current DNS server
adds each machine/host defined in the `build.yaml` to a set of A-records, thus DNS
is configured in such a way that each machine is resolvable as `<host>.<domain>.<tld>` 
e.g. `node1.bitbuild.dev`

The `project` key in the yaml file allows you to group builds logically based on 
a project, and prefixes the [Virtualbox](https://www.virtualbox.org/) machine with
the project name specified, for example: `bitbuild-node1`. This allows you to 
template multiple builds, whilst maintaining a consistent machine naming convention.

## option: machine

```YAML
- option: machine
  enabled: true
  name: node1
  description: "Primary Node"
  primary: true
  box: ubuntu/xenial64
  box_url:
  linked_clone: false
  hostname: node1
  memory: 512
  cpus: 2
  gui: false
  private_ip: 192.168.56.10
  vm_mods:
    - option: --natdnshostresolver1
      value: "on"
    - option: --ioapic
      value: "on"
  provision: true
  playbook: provisioning/ansible/playbook.yml
```

The `machine` options pretty much mimic the Vagrant `config.vm` and 
`config.vm.provider` constructs. 

- `enabled`: Enables or disables the box. You can temporarily remove a box 
    from the build  by setting to `false`
- `name`: The Vagrant identifier for the box. Will be prefixed with project name
    from the `general` block in the Virtualbox Machine Manager.
- `description`: Not used in the `Vagrantfile`, added for readability.
- `primary`: Designates the box as a primary to Vagrant when building multiple
    boxes.
- `box`: Populates `config.vm.box`. Can be a custom box or from [Atlas](https://atlas.hashicorp.com)
- `box_url`: The URL for the box if it's published somewhere else.
- `linked_clone`: Should the box be created as a linked clone. This can save quite
    a lot of space if you intend on building many boxes of the same distribution/version.
- `hostname`: Defines the actual O/S level hostname for the box. Will also be used
    to populate DNS.
- `memory`: Amount of RAM to allocate to the box.
- `cpus`: Number of virtual cores to allocate to the box.
- `gui`: (Virtualbox only) Should the box start a GUI.
- `private_ip`: The IPv4 address to assign to the box's private (host only) network
    interface. ([See below](#Miscellaneous))
- `vm_mods`: (Virtualbox only) A hash of key/value pairs that define options to be
    passed to the Virtualbox provider. Only simple option/value sets can be specified
    at the moment. (See [VBoxManage documentation](https://www.virtualbox.org/manual/ch08.html))
    - `- option`: The Virtualbox option name
    - `value`: String value of the option
- `provision`: Should the provisioning step be applied to the box.
- `playbook`: The Ansible playbook to apply to the box.

## Miscellaneous

**Console log**: By default the Virtualbox provider is configured to connect the
first serial device in the box to a file named `<hostname>-console.log`, which will
output all console (tty) messages to the file, provided that the box image has been
configured to do so.

**Private IP**: All boxes are always configured with a "Private IP", in Virtualbox
provider terms this means that a second interface is created which is connected
to the host-only network adapter. This greatly eases access to the virtual machine
without having to configure a bunch of port-forward rules for the primary network
interface which is connected to the NAT driver. It also ensures that machines are
able to easily communicate with each other.

**`printConfig.rb`**: A simple configuration printer has been provided to
"pretty print" your build configuration. 

**Ansible Playbook**: To demonstrate how Ansible playbooks can be used with the 
multibuild, a sample playbook has been included in the `provisioning/ansible`
directory that configures the NTP service on a host.

# Requirements

The only requirements are:

- [Virtualbox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/)

Both can be installed using [Homebrew](https://brew.sh/) on macOS.

# Optional (Recommended) Components

Although optional (I think...) the following components are highly recommended:

## Ansible

I/we use [Ansible](https://www.ansible.com/), so that is the only provisioner 
supported at the moment. Install via `pip` on macOS:

```bash
$ sudo easy_install pip
```
Then:
```bash
$ sudo pip install ansible
```

Detailed documentation for using Ansible to provision Vagrant boxes can be found
[here](http://docs.ansible.com/ansible/playbooks.html) and 
[here](https://www.vagrantup.com/docs/provisioning/ansible.html).

## Vagrant plugins

Some optional Vagrant plugins may be installed to ease the usage and creation
of boxes.

[vagrant-cachier](https://github.com/fgrehm/vagrant-cachier) - Will provide local
caching of packages for Linux distributions avoiding the need to re-download 
packages every time. *In this build `vagrant-cachier` is configured to make the 
cache available via NFS*.

Install with:

```bash
$ vagrant plugin install vagrant-cachier
```

[vagrant-dns](https://github.com/BerlinVagrant/vagrant-dns) - Manages DNS name 
entries for your Vagrant boxes using macOS's resolver mechanism

Install with:

```bash
$ vagrant plugin install vagrant-dns
```

# Usage

    $> vagrant up


# TODO

- [ ] Swap out [vagrant-dns](https://github.com/BerlinVagrant/vagrant-dns) for something like
    [vagrant-landrush](https://github.com/vagrant-landrush/landrush) or another 
    [dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html) type solution.
- [ ] Add [YAML](http://yaml.org/) configuration options for synced folders.
- [ ] Setup the NFS uid and gid mapping and add configuration options.
- [ ] Make the `Vagrantfile` print a pretty summary using `config.vm.post_up_message`.
- [ ] Investigate how to collect all machines in a build into a Virtualbox "group".
- [ ] Configure guest /etc/hosts or "Internal" DNS.