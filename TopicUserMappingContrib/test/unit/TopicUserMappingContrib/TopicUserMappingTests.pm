use strict;

package TopicUserMappingTests;

# Some basic tests for Foswiki::Users::TopicUserMapping
#
# The tests are performed using the APIs published by the facade class,
# Foswiki:Users, not the actual Foswiki::Users::TopicUserMapping

use base qw(FoswikiTestCase);

use Foswiki;
use Foswiki::Users;
use Foswiki::Users::TopicUserMapping;
use Error qw( :try );

my $fatwilly;
my $saveTopic;
my $ttpath;

my $testSysWeb    = 'TemporaryTopicUserMappingTestsSystemWeb';
my $testNormalWeb = "TemporaryTopicUserMappingTestsNormalWeb";
my $testUsersWeb  = "TemporaryTopicUserMappingTestsUsersWeb";
my $testUser;

sub fixture_groups {
    return ( [ 'useHtpasswdMgr', 'noPasswdMgr' ],
        [ 'NormalTopicUserMapping', 'NamedTopicUserMapping', ] );
}

sub NormalTopicUserMapping {
    my $this = shift;
    $Foswiki::Users::TopicUserMapping::TWIKI_USER_MAPPING_ID = '';
    $this->set_up_for_verify();
}

sub NamedTopicUserMapping {
    my $this = shift;

    # Set a mapping ID for purposes of testing named mappings
    $Foswiki::Users::TopicUserMapping::TWIKI_USER_MAPPING_ID = 'TestMapping_';
    $this->set_up_for_verify();
}

sub useHtpasswdMgr {
    my $this = shift;

    $Foswiki::cfg{PasswordManager} = "Foswiki::Users::HtPasswdUser";
}

sub noPasswdMgr {
    my $this = shift;

    $Foswiki::cfg{PasswordManager} = "none";
}

# Override default set_up in base class; will call it after the mapping
#  id has been set
sub set_up {
}

# Delay the calling of set_up till after the cfg's are set by above closure
sub set_up_for_verify {
    my $this = shift;

    $this->SUPER::set_up();

    my $original = $Foswiki::cfg{SystemWebName};
    $Foswiki::cfg{Htpasswd}{FileName} =
      "$Foswiki::cfg{TempfileDir}/junkhtpasswd";
    $Foswiki::cfg{UsersWebName}         = $testUsersWeb;
    $Foswiki::cfg{SystemWebName}        = $testSysWeb;
    $Foswiki::cfg{LocalSitePreferences} = "$testUsersWeb.SitePreferences";
    $Foswiki::cfg{UserMappingManager}   = 'Foswiki::Users::TopicUserMapping';
    $Foswiki::cfg{Register}{AllowLoginName}            = 1;
    $Foswiki::cfg{Register}{EnableNewUserRegistration} = 1;

    try {
        $fatwilly = new Foswiki( $Foswiki::cfg{AdminUserLogin} );
        Foswiki::Func::createWeb($testUsersWeb);

        # the group is recursive to force a recursion block
        Foswiki::Func::saveTopic( $testUsersWeb, $Foswiki::cfg{SuperAdminGroup},
            undef, "   * Set GROUP = $Foswiki::cfg{SuperAdminGroup}\n" );

        Foswiki::Func::createWeb( $testSysWeb,    $original );
        Foswiki::Func::createWeb( $testNormalWeb, '_default' );

        my $oprefs =
          Foswiki::Meta->load( $fatwilly, $testSysWeb,
            $Foswiki::cfg{SitePrefsTopicName} );
        my $nprefs =
          Foswiki::Meta->new( $fatwilly, $testSysWeb,
            $Foswiki::cfg{SitePrefsTopicName},
            $oprefs->text() );
        $nprefs->copyFrom($oprefs);
        $nprefs->save();

        $testUser = $this->createFakeUser($fatwilly);
    }
    catch Foswiki::AccessControlException with {
        my $e = shift;
        $this->assert( 0, $e->stringify() );
    }
    catch Error::Simple with {
        $this->assert( 0, shift->stringify() || '' );
    };
}

sub tear_down {
    my $this = shift;

    $this->removeWebFixture( $fatwilly, $testUsersWeb );
    $this->removeWebFixture( $fatwilly, $testSysWeb );
    $this->removeWebFixture( $fatwilly, $testNormalWeb );
    unlink $Foswiki::cfg{Htpasswd}{FileName};
    $fatwilly->finish();
    $this->SUPER::tear_down();
}

sub new {
    my $self = shift()->SUPER::new(@_);
    return $self;
}

my $initial = <<'THIS';
	* A - <a name="A">- - - -</a>
    * AttilaTheHun - 10 Jan 1601
	* B - <a name="B">- - - -</a>
	* BungditDin - 10 Jan 2004
	* C - <a name="C">- - - -</a>
	* D - <a name="D">- - - -</a>
	* E - <a name="E">- - - -</a>
	* F - <a name="F">- - - -</a>
	* G - <a name="G">- - - -</a>
	* GungaDin - 10 Jan 2004
	* H - <a name="H">- - - -</a>
	* I - <a name="I">- - - -</a>
	* J - <a name="J">- - - -</a>
	* K - <a name="K">- - - -</a>
	* L - <a name="L">- - - -</a>
	* M - <a name="M">- - - -</a>
	* N - <a name="N">- - - -</a>
	* O - <a name="O">- - - -</a>
	* P - <a name="P">- - - -</a>
	* Q - <a name="Q">- - - -</a>
	* R - <a name="R">- - - -</a>
	* S - <a name="S">- - - -</a>
	* SadOldMan - sad - 10 Jan 2004
	* SorryOldMan - 10 Jan 2004
	* StupidOldMan - 10 Jan 2004
	* T - <a name="T">- - - -</a>
	* U - <a name="U">- - - -</a>
	* V - <a name="V">- - - -</a>
	* W - <a name="W">- - - -</a>
	* X - <a name="X">- - - -</a>
	* Y - <a name="Y">- - - -</a>
	* Z - <a name="Z">- - - -</a>
THIS

sub createFakeUser {
    my ( $this, $fatwilly, $text, $name ) = @_;
    $this->assert( Foswiki::Func::webExists( $Foswiki::cfg{UsersWebName} ) );
    $name ||= '';
    my $base = "TemporaryTestUser" . $name;
    my $i    = 0;
    while (
        Foswiki::Func::topicExists( $Foswiki::cfg{UsersWebName}, $base . $i ) )
    {
        $i++;
    }
    $text ||= '';
    my $meta =
      Foswiki::Meta->new( $fatwilly, $Foswiki::cfg{UsersWebName}, $base . $i );
    $meta->put(
        "TOPICPARENT",
        {
            name => $Foswiki::cfg{UsersWebName} . '.'
              . $Foswiki::cfg{HomeTopicName}
        }
    );
    Foswiki::Func::saveTopic( $Foswiki::cfg{UsersWebName},
        $base . $i, undef, $text, $meta );
    push( @{ $this->{fake_users} }, $base . $i );
    return $base . $i;
}

sub verify_AddUsers {
    my $this = shift;
    my $ttpath =
"$Foswiki::cfg{DataDir}/$Foswiki::cfg{UsersWebName}/$Foswiki::cfg{UsersTopicName}.txt";
    my $me = $Foswiki::cfg{Register}{RegistrationAgentWikiName};

    open( my $F, '>', $ttpath ) || $this->assert( 0, "open $ttpath failed" );
    print $F $initial;
    close($F);
    chmod( 0777, $ttpath );
    $fatwilly->{users}->{mapping}->addUser( "guser", "GeorgeUser", $me );
    open( $F, '<', $ttpath );
    local $/ = undef;
    my $text = <$F>;
    close($F);
    $this->assert_matches(
        qr/\n\s+\* GeorgeUser - guser - \d\d \w\w\w \d\d\d\d\n/s, $text );
    $fatwilly->{users}->{mapping}->addUser( "auser", "AaronUser", $me );
    open( $F, '<', $ttpath );
    local $/ = undef;
    $text = <$F>;
    close($F);
    $this->assert_matches( qr/AaronUser.*GeorgeUser/s, $text );
    $fatwilly->{users}->{mapping}->addUser( "zuser", "ZebediahUser", $me );
    open( $F, '<', $ttpath );
    local $/ = undef;
    $text = <$F>;
    close($F);
    $this->assert_matches( qr/Aaron.*George.*Zebediah/s, $text );
}

sub verify_Load {
    my $this = shift;

    my $me = $Foswiki::cfg{Register}{RegistrationAgentWikiName};
    $ttpath =
"$Foswiki::cfg{DataDir}/$Foswiki::cfg{UsersWebName}/$Foswiki::cfg{UsersTopicName}.txt";

    open( my $F, '>', $ttpath ) || $this->assert( 0, "open $ttpath failed" );
    print $F $initial;
    close($F);

    my $zuser_id =
      $fatwilly->{users}->{mapping}->addUser( "zuser", "ZebediahUser", $me );
    my $auser_id =
      $fatwilly->{users}->{mapping}->addUser( "auser", "AaronUser", $me );
    my $guser_id =
      $fatwilly->{users}->{mapping}->addUser( "guser", "GeorgeUser", $me );

    # deliberate repeat
    $fatwilly->{users}->{mapping}->addUser( "zuser", "ZebediahUser", $me );

    # find a nonexistent user to force a cache read
    $fatwilly->finish();
    $fatwilly = new Foswiki();
    my $n = $fatwilly->{users}->{mapping}->login2cUID("auser");
    $this->assert_str_equals( $n, $auser_id );
    $this->assert_str_equals( "AaronUser",
        $fatwilly->{users}->getWikiName($n) );
    $this->assert_str_equals( "auser", $fatwilly->{users}->getLoginName($n) );

    my $i = $fatwilly->{users}->eachUser();
    my @l = ();
    while ( $i->hasNext() ) {
        push( @l, $i->next() );
    }
    my $k = join( ",", sort map { $fatwilly->{users}->getWikiName($_) } @l );
    $this->assert( $k =~ s/^AaronUser,//,          $k );
    $this->assert( $k =~ s/^AdminUser,//,          $k );
    $this->assert( $k =~ s/^AttilaTheHun,//,       $k );
    $this->assert( $k =~ s/^BungditDin,//,         $k );
    $this->assert( $k =~ s/^GeorgeUser,//,         $k );
    $this->assert( $k =~ s/^GungaDin,//,           $k );
    $this->assert( $k =~ s/^ProjectContributor,//, $k );
    $this->assert( $k =~ s/^RegistrationAgent,//,  $k );
    $this->assert( $k =~ s/^SadOldMan,//,          $k );
    $this->assert( $k =~ s/^SorryOldMan,//,        $k );
    $this->assert( $k =~ s/^StupidOldMan,//,       $k );
    $this->assert( $k =~ s/^UnknownUser,//,        $k );
    $this->assert( $k =~ s/^WikiGuest,//,          $k );
    $this->assert( $k =~ s/^ZebediahUser//,        $k );
    $this->assert_str_equals( "", $k );
}

sub groupFix {
    my $this = shift;
    my $me   = $Foswiki::cfg{Register}{RegistrationAgentWikiName};
    $fatwilly->{users}->{mapping}->addUser( "auser", "AaronUser",    $me );
    $fatwilly->{users}->{mapping}->addUser( "guser", "GeorgeUser",   $me );
    $fatwilly->{users}->{mapping}->addUser( "zuser", "ZebediahUser", $me );
    $fatwilly->{users}->{mapping}->addUser( "auser", "AaronUser",    $me );
    $fatwilly->{users}->{mapping}->addUser( "guser", "GeorgeUser",   $me );
    $fatwilly->{users}->{mapping}->addUser( "zuser", "ZebediahUser", $me );
    $fatwilly->{users}->{mapping}->addUser( "scum",  "ScumUser",     $me );
    Foswiki::Func::saveTopic( $testUsersWeb, 'AmishGroup', undef,
        "   * Set GROUP = AaronUser,%MAINWEB%.GeorgeUser, scum\n" );
    Foswiki::Func::saveTopic( $testUsersWeb, 'BaptistGroup', undef,
        "   * Set GROUP = GeorgeUser,$testUsersWeb.ZebediahUser\n" );
    Foswiki::Func::saveTopic( $testUsersWeb, 'MultiLineGroup', undef,
"   * Set GROUP = GeorgeUser,$testUsersWeb.ZebediahUser\n   AaronUser, scum\n"
    );
}

sub verify_getListOfGroups {
    my $this = shift;
    $this->groupFix();
    my $i = $fatwilly->{users}->eachGroup();
    my @l = ();
    while ( $i->hasNext() ) { push( @l, $i->next() ) }
    my $k = join( ',', sort @l );
    $this->assert_str_equals(
        "AdminGroup,AmishGroup,BaptistGroup,BaseGroup,MultiLineGroup", $k );
}

sub verify_groupMembers {
    my $this = shift;
    $this->groupFix();
    my $g = "AmishGroup";
    $this->assert( $fatwilly->{users}->isGroup($g) );
    my $i = $fatwilly->{users}->eachGroupMember($g);
    my @l = ();
    while ( $i->hasNext() ) { push( @l, $i->next() ) }
    my $k = join( ',', map { $fatwilly->{users}->getLoginName($_) } sort @l );
    $this->assert_str_equals( "auser,guser,scum", $k );

    $g = "BaptistGroup";
    $this->assert( $fatwilly->{users}->isGroup($g) );
    $i = $fatwilly->{users}->eachGroupMember($g);
    @l = ();
    while ( $i->hasNext() ) { push( @l, $i->next() ) }
    $k = join( ',', map { $fatwilly->{users}->getLoginName($_) } sort @l );
    $this->assert_str_equals( "guser,zuser", $k );

    $g = "MultiLineGroup";
    $this->assert( $fatwilly->{users}->isGroup($g) );
    $i = $fatwilly->{users}->eachGroupMember($g);
    @l = ();
    while ( $i->hasNext() ) { push( @l, $i->next() ) }
    $k = join( ',', map { $fatwilly->{users}->getLoginName($_) } sort @l );
    $this->assert_str_equals( "auser,guser,scum,zuser", $k );
}

1;
