<?php
//ini_set('display_errors', 1);
//ini_set('display_startup_errors', 1);
//error_reporting(E_ALL);

// CONSTANTS FROM YOUR APP ON WORKPLACE
$app_secret = 'app_secret';
$access_token = 'access_token';
$my_verify_token = "my_arbitrary_verify_token";

// CODE TO SUBSCRIBE/MODIFY THE WEBHOOK ON WORKPLACE - Checking verify token and returning challenge
$verify_token = isset($_GET['hub_verify_token']) ? $_GET['hub_verify_token'] : '';
if (isset($_GET['hub_challenge']) && $verify_token == $my_verify_token) {
        echo $_GET['hub_challenge'];
        logging_to_txt_file("Webhook subscribed/modified");
        exit();
}

// CODE TO VERIFY THE WEBHOOK REQUESTS - Getting the headers and comparing the signature
$headers = getallheaders();
$request_body = file_get_contents('php://input');
$signature = "sha1=" . hash_hmac('sha1', $request_body, $app_secret);
//logging_to_txt_file("calculated signature " . $signature);
//logging_to_txt_file("headers " . json_encode($headers, true));

if (!isset($headers['X-Hub-Signature']) || ($headers['X-Hub-Signature'] != $signature)) {
        logging_to_txt_file("X-Hub-Signature not matching");
        exit("X-Hub-Signature not matching");
}

// HANDLE THE DATA SENT FROM WORKPLACE
$data = json_decode($request_body, true);
logging_to_txt_file($request_body);
$webhook_event = $data['entry'][0]['changes'][0]["value"]["event"];
$email_modified_user = $data['entry'][0]['changes'][0]["value"]["target_email"];
$id_modified_user = $data['entry'][0]['changes'][0]["value"]["target_id"];

// Modify user email as they are deactivated
if ("ADMIN_DEACTIVATE_ACCOUNT" != $webhook_event) {
        logging_to_txt_file("No need to further process this event: " . $webhook_event);
        exit("No need to further process this event: " . $webhook_event);
} else
        logging_to_txt_file("Processing event: " . $webhook_event);

// First we define te new email, which is going to be the old one plus the date of today
$today_date = date('Y-m-d');
$email_modified_user_pieces = explode ("@", $email_modified_user);
$new_email_modified_user = implode("@", array($email_modified_user_pieces[0] . '_' . $today_date, $email_modified_user_pieces[1]));

// Then we modify the user email address
$server_output = modify_user_email_address($id_modified_user, $new_email_modified_user, $access_token);

// Finally we deal with the server results as we deem appropriate
if ($server_output == "OK") { echo "ALRIGHTY!"; } else { echo "NOPE. " . $server_output; }
logging_to_txt_file("FB server output= " . $server_output . "\r\n");

// FUNCTIONS
function modify_user_email_address($id_user, $new_email_address, $api_access_token) {
        // Create and populate the curl object  
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL,"https://graph.workplace.com/" . $id_user);
        curl_setopt($ch, CURLOPT_POST, 1);
        $fields = array(
                "email" => $new_email_address
        );
        $fields_string = json_encode($fields);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $fields_string);
        curl_setopt( $ch, CURLOPT_HTTPHEADER, array(
                'Content-Type:application/json',
                'User-Agent:GithubRep-WebHookSecurityUserDeactivation',
                'Authorization:Bearer ' . $api_access_token
        ));
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

        // Send the curl request and receive the results
        $server_output = curl_exec($ch);
        curl_close ($ch);
        logging_to_txt_file("Modifying user " . $id_user . " - New email: " . $new_email_address);

        // We return the results from server
        return $server_output;
}

function logging_to_txt_file($text_to_log) {
        $fp = fopen('my_log_file.txt', 'a');
        $datetime_now = date('Y-m-d H:i:s');
        fwrite($fp, '[' . $datetime_now . '] ' . $text_to_log . "\r\n");
        fclose($fp);
}

?>
