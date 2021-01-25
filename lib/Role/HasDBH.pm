package Role::HasDBH;
use Mouse::Role;
use FindBin '$Bin';
use lib "$Bin/../lib";
use Model::Schema;
use Config::JSON;
use Path::Class qw(file);

has dbh => (is => 'rw', isa => 'Model::Schema', lazy_build => 1);

sub _build_dbh {
    my $self = shift;
    my $config = Config::JSON->new(pathToFile => file($Bin)->dir->file('config.json'));
    my $dbpath = file($Bin)->dir->file('storage', 'database.db');
    my $dsn = $config->get('dbdriver').$dbpath;
    my $schema = Model::Schema->connect(
            $dsn,
            $config->get('user'),
            $config->get('password'),
            $config->get('parameters'),
        );
    #$schema->storage->debug(1);
    return $schema;
}

1;
