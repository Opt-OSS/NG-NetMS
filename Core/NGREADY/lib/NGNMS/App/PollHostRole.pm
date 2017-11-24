package NGNMS::App::PollHostRole;

use strict;
use warnings FATAL => 'all';
use File::Path qw(make_path);
use Moo::Role;
use Emsgd qw(diag);
use Module::Pluggable search_path => 'NGNMS::Plugins', require => 1;
use NGNMS::App::PollHostPluginInterface;
use NGNMS::Net::Nmap;
use NGNMS::Log4;
use NGNMS::App::Crypt;
with  "NGNMS::App::Helpers", "NGNMS::App::Database";
with "NGNMS::Log4Role";
my @pollHostPluginsCanSNMP; # array of classes that implements PollHost::checkSNMPsysObjectID
my @pollHostPluginsCanSupport; # array of classes that implements PollHost::checkDeviceSupported
my NGNMS::App::PollHostPluginInterface $plugin_module;
my $rt_id;
my $host_ip;
my $host_name;

has snmp_status => (is => 'rw');
has ssh_status => (is => 'rw');
has nmap_status => (is => 'rw');
has override_hosttype => (is => 'rw');
has sysObjIdResult => (is => 'rw');
#@returns NGNMS::App::Crypt
has crypt => (is => 'lazy', builder => sub{
            my $self = shift;
            my $crypt = NGNMS::App::Crypt->new(
                DB                  => $self->DB,
                username            => $self->host_user,
                password            => $self->host_password,
                privileged_password => $self->host_priveleged_password,
                transport           => $self->host_transport,
                community           => $self->host_community,
                port                => $self->host_port,
                timeout                => $self->host_timeout,

            );
        });
# ------------------------------------------------------
#=for runPollHost()
#check arguments,
#get and instantiate plugins,
#check host exists in DB
#if any fails, stop host processing
#
#=cut


sub find_plugins {
    my $self = shift;
    @pollHostPluginsCanSNMP = (); #clear array so no duplicates
    @pollHostPluginsCanSupport = (); #clear array so no duplicates
    #**
    #  $self->plugins - list of modules returned by Module::Pluggable with search_path => 'NGNMS::Plugins'
    #**
    foreach my NGNMS::App::PollHostPluginInterface $plugin ($self->plugins) {
        push (@pollHostPluginsCanSNMP, $plugin->new)
            if $plugin->can('checkCanPollHost') && $plugin->checkCanPollHost() && $plugin->can('checkDeviceSupported') && !Moo::Role->is_role($plugin);
        push (@pollHostPluginsCanSupport, $plugin->new)
            if $plugin->can('checkCanPollHost') && $plugin->checkCanPollHost() && $plugin->can('checkSNMPsysObjectID') && !Moo::Role->is_role($plugin);
    }
}
sub runPollHost {
    #        diag 'run Poll';
    my $self = shift;
    my $host = $self->host;
    $plugin_module = undef;
    $self->logger->error("DIE: host perameter required in poll run mode") && return 0 unless defined $host;

    ($rt_id, $host_name, $host_ip) = $self->DB->getRouterInfo($host);
    #    $self->put_debug_key('host',$host_ip);
    $self->override_hosttype($self->host_type);
    #todo move inject into App
    $self->logger->debug("already exists, skip injecting") unless $rt_id && $self->inject;
    if (!$rt_id) {
        $self->logger->error ("host not found in DB") && return 0 unless $self->inject;
        $rt_id = $self->DB->addRouter($host, $host, 'up');
        $self->logger->error ("can not add router") && return 0 unless $rt_id;
        $self->DB->setHostVendor($rt_id, $self->host_type);

        $self->logger->info("host injected into DB as " . $self->host_type);
        ($rt_id, $host_name, $host_ip) = $self->DB->getRouterInfo($host);
    }
    $self->logger->error ("host not found in DB") && return 0 unless $rt_id;

    $self->find_plugins();

    $self->ssh_status(0);
    $self->start_poll_processing;

    # in case if DNS name failed get host ip addr and re-try to connect using it instead
    #try another round
    if (!$self->ssh_status) {
        $self->logger->info("Could not get configs default configs");
        if ($host ne $host_ip) {
            $self->logger->info("Attempt to get configs for  hostname  by  $host_ip");
            local $NGNMS::Log4::package_prefix = $self->host . "($host_ip) :: Pollhost :: ";
            $self->host($host_ip);
            #            $self->set_logger();
            $self->start_poll_processing;
        }
        else {
            $self->logger->warn("Could not get configs  by  hostname or ip $host_ip");

        }
    }
    $self->setHostStatus;
    return $self->ssh_status;
}
sub _setNmapStatus {
    my $self = shift;
    $self->nmap_status(NGNMS::Net::Nmap::getNmapResponse($self->host));
}
sub doNmap {
    my $self = shift;

    $self->_setNmapStatus;
    #    diag "NO manual type: nmap status ".$self->nmap_status."; host type ".($self->host_type || 'undef');
    $self->DB->setHostStatus($rt_id, ($self->host_type ? 'Down' : 'Unknown')) && return
        if !$self->nmap_status;
    my $st = $plugin_module ? 'Unmanaged' : 'Unsupported';
    $self->DB->setHostStatus($rt_id, ($self->host_type ? $st : 'New')) && return
        if $self->nmap_status;
}
sub setHostStatus {
    my $self = shift;


    #if SSH is OK set UP
    #    $self->DB->setHostStatus( $rt_id, 'up') && return if $self->ssh_status;
    if (!$self->override_hosttype) {
        #        diag "NO manual type: snmp_status  ".$self->snmp_status."; ssh_status ". $self->ssh_status ."; host type ".($self->host_type || 'undef');
        ############## NO MANUAL TYPE
        ## when XXX = [snmp ssh type_in_DB]
        # "DO NMAP     when 000"
        # "DO NMAP     when 001"
        if (!$self->snmp_status && !$self->ssh_status) {
            $self->doNmap;
            return;
        }
        #"ERROR       when 010 impossible if manual type is NOT provided "
        # it is result BY DEFAULT
        #"UP          when 011 fallback to DB type"
        $self->DB->setHostStatus($rt_id, 'Up') && return
            if !$self->snmp_status && $self->ssh_status && $self->host_type;
        #"UNMANAGED   when 100 and plugin is exists"
        # "UNSUPPORTED when 100 and plugin is NOT exists"
        $self->DB->setHostStatus($rt_id, ($plugin_module ? 'Unmanaged' : 'Unsupported')) && return
            if $self->snmp_status && !$self->ssh_status && !$self->host_type;


        # "UNMANAGED   when 101"
        $self->DB->setHostStatus($rt_id, 'Unmanaged') && return
            if $self->snmp_status && !$self->ssh_status && $self->host_type;
        # "UP          when 110"
        # "UP          when 111"
        $self->DB->setHostStatus($rt_id, 'Up') && return
            if $self->snmp_status && $self->ssh_status;

    }
    else {
        #       diag "Manual type: snmp_status  ".$self->snmp_status."; ssh_status ". $self->ssh_status ."; host type ".($self->host_type || 'undef');
        ############## WITH MANUAL TYPE
        ## [snmp ssh]
        # "DO NMAP     when 00";
        if (!$self->snmp_status && !$self->ssh_status) {
            $self->doNmap;
            return;
        }
        # "UP          when 01";
        # "UP          when 11";
        $self->DB->setHostStatus($rt_id, 'Up') && return
            if $self->ssh_status;
        # "UNMANAGED   when 10 and plugin is exists";
        # "UNSUPPORTED when 10 and plugin is NOT exists";
        $self->DB->setHostStatus($rt_id, ($plugin_module ? 'Unmanaged' : 'Unsupported')) && return
            if $self->snmp_status && !$self->ssh_status;
    }
    $self->DB->setHostStatus($rt_id, 'ERROR');
    return;
}
# ------------------------------------------------------
#=for start_poll_processing()
#get  connect credentials for session
#find plugin for host (if host_type given in cmd arguments, force command line argument, else try to find host type via SNMP)
#if no plugin found, stop host processing
#
#=cut

sub start_poll_processing {
    my $self = shift;
    my $host = $self->host;

    $self->logger->info("============= Start  Processing =================");
    my $credentials = $self->crypt->getHostCredentials($host);
    $self->snmp_status($self->getTypeBySNMP($credentials->{community}));
    #if host type forced from command line, try to get plugin by host_type
    $plugin_module = $self->host_type ? $self->getPollHostPluginByHostType : $self->getPollHostPluginBySNMP;
    $self->logger->error("Could not get PollHost plugin type:" . ($self->host_type ? $self->host_type : "unknown")) && return 0 unless $plugin_module;
    $self->logger->info("Using " . $plugin_module->getModuleName);
    $self->ssh_status($self->processPollHost($credentials));
    return $self->ssh_status;
}
# ------------------------------------------------------
#=for processPollHost($credentials)
#connect to host with $credentials, inject session into plugin and process host data
#
#=cut
sub processPollHost {
    my $self = shift;
    my $credentials = shift;

    $self->logger->info("Skipping polling: conection failed") && return 0 unless $self->setSession($credentials);
    $self->logger->info("Skipping polling: beforeProcessing checks failed") && return 0 unless $plugin_module->beforeProcessing();
    #Process host
    my $res = 1;
    eval {
        $self->processModel();
        $self->processVendor();
        $self->processHostname();
        $self->processHardware();
        $self->processSoftware();
        $self->processLocation();
        $self->processInterfaces();
        $self->processIpLayer();
        $self->processConfig();
    };
    if ($@) {
        $self->logger->warn("Process died :" . $@);
        $res = 0;
    };
    $plugin_module->session->connection->close();
    return $res;

}

sub processModel {
    my $self = shift;
    my $res = $plugin_module->getModel();
    $self->logger->warn ("Bad model") && return unless $res;
    $self->DB->setHostModel($rt_id, $res);

}
sub processVendor {
    my $self = shift;
    my $res = $plugin_module->getVendor();
    $self->logger->warn ("Bad vendor") && return unless $res;
    $self->DB->setHostVendor($rt_id, $res);

}
sub processHostname {
    my $self = shift;
    my $res = $plugin_module->getHostName();
    #    diag($res);
    $self->DB->setHostName($rt_id, $res) if $res && ($res ne $host_name);
}
sub processHardware {
    my $self = shift;
    my $res = $plugin_module->getHardware();
    $self->logger->warn ("Bad hardware") && return unless $res;
    $self->DB->clearHostHardwareInfo($rt_id);
    $self->DB->setHostHardwareInfo($rt_id, $res);

}
sub processSoftware {
    my $self = shift;
    my $res = $plugin_module->getSoftware();

    $self->logger->warn ("Bad software") && return unless $res;
    $self->DB->clearHostSoftwareInfo($rt_id);
    $self->DB->setHostSoftwareInfo($rt_id, $res);
}
sub processLocation {
    my $self = shift;
    my $res = $plugin_module->getLocation();
    $self->logger->warn ("Bad location ") && return unless $res;
    $self->DB->setHostLocation($rt_id, $res);
}

sub processInterfaces {
    my $self = shift;
    my ($ph_if, $ifc ) = $plugin_module->getInterfaces();
    $self->processPhysicalInterfaces($ph_if);
    $self->processLogicalInterfaces($ph_if, $ifc);
}


sub processIpLayer {
    my $self = shift;
    my $res = $plugin_module->getIpLayer();
    $self->logger->warn("Bad IP layer for " . $self->host) && return unless $res;
    $self->DB->setHostLayer($rt_id, $res);
}
sub processPhysicalInterfaces {
    my $self = shift;
    my $ph_if = shift; #reference to Physical int array
    $self->logger->warn ("got empty Pysical Interface list") unless %$ph_if;
    $self->DB->markPhInterfacesToBePolled($rt_id);
    while (my ($phys_in_name, $data) = each %$ph_if) {
        $data->{name} = $phys_in_name;
        $data->{ph_int_id} = $self->DB->setPhInterface($rt_id, $data);
        $self->logger->warn("error adding physical interface $phys_in_name with id=$rt_id") unless $data->{ph_int_id};
    }
    $self->DB->deletePhInterfacesPolledButNotFound($rt_id);
}

sub processLogicalInterfaces {
    my $self = shift;
    my $ph_if = shift; #reference to Physical int array
    my $ifc = shift; #reference to Logical int array
    $self->logger->warn ("got empty Logical Interface list") && return unless (defined $ifc && %$ifc);

    $self->DB->markInterfacesToBePolled($rt_id);
    while (my ($logic_name, $data) = each %$ifc) {
        my $ph_int_id = $ph_if->{$data->{physical_interface_name}}->{ph_int_id};
        $self->logger->warn("error adding logical interface $logic_name  to $rt_id") && next unless $ph_int_id;
        $data->{name} = $logic_name;
        $data->{ph_int_id} = $ph_int_id;
        $self->DB->setInterface($rt_id, $data);
    }
    $self->DB->deleteInterfacesPolledButNotFound($rt_id);

}
sub processConfig {
    my $self = shift;
    my $config = $plugin_module->getConfig();
    $self->DB->addConfig($rt_id, $config) if ($config);
}
#=for setSession($credentials)
#Try to connect to host using $credentials
#and plugin personality
#if success inject session into plugin and continue
#if fails, stop host processing
#
#=cut

sub setSession {
    my $self = shift;
    my $credentials = shift;
    #inject session
    my $app = NGNMS::App->instance;

    my $snmp_sess = $app->snmp_session_factory();
    $snmp_sess->connect($credentials->{community}, $host_ip, $host_name);
    $plugin_module->snmp_session($snmp_sess);
    my $session_debug = 'error';
    $session_debug = 'notice' if $self->verbose eq 'INFO';
    $session_debug = 'debug' if $self->verbose eq 'DEBUG';
    #    diag $self->verbose_level;
    my $params = {
        personality         => 'ios',
        add_library         => undef,
        transport           => $credentials->{transport} || 'Telnet',
        port                => $credentials->{port},
        timeout             => $credentials->{timeout} || 10,
        host                => $self->host,
        requires_privileged => 0,
        debug               => $session_debug, #Net::Cli debug
        verbose             => $self->verbose, #App log level
        privileged_paging   => 0,
        wake_up             => 0,
        connect_options     => { opts => $credentials->{connect_options} },

        #        username            => $credentials->{username},
        #        password            => $credentials->{password},
        #        privileged_password => $credentials->{privileged_password},

    };
    $params = $plugin_module->prepare_connection($params);
    my $sess = $app->session_factory();
    #    diag $credentials;
    if (exists $credentials->{jumphost}) {
        push @{ $credentials->{jumphost}{connect_options} },
            ('-p', $credentials->{jumphost}{port}) if $credentials->{jumphost}{port};
        $params->{jumphost} = Net::Appliance::Session->new(
            transport       => 'SSH',
            personality     => 'bash',
            timeout            => $credentials->{jumphost}{timeout} || 10,
            host            => $credentials->{jumphost}{host},
            username        => $credentials->{jumphost}{username},
            password        => $credentials->{jumphost}{password},
            connect_options => { opts => $credentials->{jumphost}{connect_options} },

        );
    }
#            diag($params);
    $self->logger->fatal("Could non create session ") && return 0 unless $sess;
    my $path = ($ENV{'NGNMS_DATA'} || '.') . '/rtconfig/' . $rt_id;
    make_path($path);
    $self->logger->fatal("Cannot create directory '$path'") && return 0 unless (-d $path);
    $sess->record_dir($path);
    my $c = $sess->connect($params, {
            username            => $credentials->{username},
            password            => $credentials->{password},
            privileged_password => $credentials->{privileged_password},
        });
    $self->logger->info("Could not connect") && return 0 if $c ne 'ok';

    $self->logger->info("SUCCESS: connected");

    $plugin_module->session($sess);
    return 1;

}

#=for getPollHostPluginByHostType()
#if a $self->host_type option is set in the command line, returns plugin to process the host
#by searching a plugin that support the $self->host_type
#if no plugin found returns 0
#
#=cut

sub getPollHostPluginByHostType {
    my $self = shift;
    $self->logger->debug("Search plugin by command-line or DB host-type: " . $self->host_type);
    for my NGNMS::App::PollHostPluginInterface $plugin (@pollHostPluginsCanSupport) {
        return $plugin if $plugin->checkDeviceSupported($self->host_type);
    }
    return undef;
}

#=for getPollHostPluginBySNMP($community)
#If $self->host_type option is NOT set in the command line, returns plugin to process the host
#by request a host type via SNMP and searching the plugin that supports returned sysObjectID.0.
#If SNMP request fails, get a vendor from DB, set $self->host_type and try to find plugin via  getPollHostPluginByHostType().
#If no plugin found returns 0
#
#=cut

sub getTypeBySNMP {
    my $self = shift;

    if ($self->play) {
        $self->logger->debug("SNMP not used in Play mode");
        return;
    }

    my ($community) = @_;
    my ($mib, $snmp_error) = $self->getSysObjectID($self->host, $community);

    $self->sysObjIdResult($mib);
    $self->logger->debug("Search plugin by SNMP response ");
    $self->logger->debug("  SMNP: $snmp_error") if $snmp_error;
    $self->logger->debug("  SMNP: wrong response") unless $self->sysObjIdResult;
    return ($self->sysObjIdResult && !$snmp_error);
}

sub getPollHostPluginBySNMP {
    my $self = shift;
    if ($self->snmp_status) {
        $self->logger->debug("  SNMP response is: " . $self->sysObjIdResult);
        # --- 1 - SNMP
        for my NGNMS::App::PollHostPluginInterface $plugin (@pollHostPluginsCanSNMP) {
            return $plugin if $plugin->checkSNMPsysObjectID($self->sysObjIdResult);
        }
    }
    else {
        # --- 2 no SNMP, try get latest known from DB and find plugin by getPollHostPluginByHostType()
        $self->logger->debug("  Fall back to DB:");
        my $vendor = $self->DB->getHostVendor($self->host);
        $self->logger->warn("No hosttype in DB") && return unless $vendor;
        $self->host_type($self->trim($vendor));
        return $self->getPollHostPluginByHostType;
    }

    return;
}

sub getPluginModule {
    return $plugin_module;
}
1;
# ABSTRACT: This file is part of open source NG-NetMS tool.
