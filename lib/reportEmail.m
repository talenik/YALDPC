function reportEmail( subject, message, cfg )
%reportEmail - sends email using given parameters
%
% reportEmail( subject, message, cfg )
%	subject - string to use as email subject
%	message - a string holding the message body
%		( ideally MATLAB parseable code )
%	cfg	-	config structure to access SMTP server
%			carefull this will contain sensitive data,
%			store the config structure in a separate .m file in a private location
%		cfg.smtp - SMTP server
%		cfg.user - SMTP server username
%		cfg.pass - SMTP server password (cleartext)
%		cfg.from - source email address
%		cfg.to	 - destination email address 
%
%		default file (not included): '../../secretEmailCfg.m'

setpref('Internet','SMTP_Server', cfg.smtp ) ;
setpref('Internet','E_mail', cfg.from ) ;
setpref('Internet','SMTP_Username', cfg.user ) ;
setpref('Internet','SMTP_Password', cfg.pass ) ;

sendmail( cfg.to, subject, message ) ;