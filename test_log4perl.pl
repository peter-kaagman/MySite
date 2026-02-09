use strict;
use warnings;
use Log::Log4perl;

my $log_conf = q(
  log4perl.rootLogger = DEBUG, LOGFILE, STDERR
  log4perl.appender.LOGFILE = Log::Log4perl::Appender::File
  log4perl.appender.LOGFILE.filename = logs/mysite.log
  log4perl.appender.LOGFILE.mode = append
  log4perl.appender.LOGFILE.layout = PatternLayout
  log4perl.appender.LOGFILE.layout.ConversionPattern = [%d] [%p] %m%n
  log4perl.appender.STDERR = Log::Log4perl::Appender::Screen
  log4perl.appender.STDERR.stderr = 1
  log4perl.appender.STDERR.layout = PatternLayout
  log4perl.appender.STDERR.layout.ConversionPattern = [%d] [%p] %m%n
);

Log::Log4perl->init(\$log_conf);
my $logger = Log::Log4perl->get_logger();

$logger->debug("Test log to file and console");

print "Done. Check logs/mysite.log for output.\n";
