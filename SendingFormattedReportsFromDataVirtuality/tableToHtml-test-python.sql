/*
select x.html from (call x_utils.tableToHtml('views.SampleOfData')) x;;
*/

begin

-- CALL "SYSADMIN.execExternalProcess"("command" => 'python3 report.py',"args" => args);

declare string subject = 'View your new report ' || FORMATTIMESTAMP(now(), 'MM.dd.yyyy ''at'' hh:mm:ss');

call "UTILS.sendMail"(
    "Recipients" => 'datavirtuality@yopmail.com',
    "Subject" => subject,
    "Body" => (select to_chars(x.file, 'UTF-8') from (CALL python_reporting_dv.getFiles("pathAndPattern" => 'report.html')) x)
);

select subject;

end;;







