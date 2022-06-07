/*
select x.html from (call x_utils.tableToHtml_V2('views.SampleOfData')) x;;
*/

begin

declare string template = '
<!DOCTYPE html>
<html>
<title>
    Test Report
</title>
<style type="text/css">
</style>

<body>
    <h1>Report Title</h1>
    <!-- Put table here -->
</body>
</html>';

--declare string html_table = (select x.html from (call x_utils.tableToHtml('views.SampleOfData')) x);
declare string html_table = (select x.html from (call x_utils.tableToHtml_V2('views.SampleOfData')) x);
declare string html = replace(template, '<!-- Put table here -->', html_table);
declare string subject = 'View your new report ' || FORMATTIMESTAMP(now(), 'MM.dd.yyyy ''at'' hh:mm:ss');

call "UTILS.sendMail"(
    "Recipients" => 'datavirtuality@yopmail.com',
    "Subject" => subject,
    "Body" => cast(html as clob)
);

select subject;

end;;
