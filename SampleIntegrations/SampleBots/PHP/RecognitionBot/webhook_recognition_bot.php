<?php
// Variables to be replaced
// Ideally we would store them securely outside of this script
$access_token = 'replace_with_your_access_token';
$verify_token = 'replace_with_your_verify_token';

// Enabling errors for debugging.
// Make sure to comment it before pushing it to production
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// We need to response to the challenge when we save changes for webhooks in the Workplace Integrations panel
if (isset($_GET['hub_verify_token']) && $_GET['hub_verify_token'] == $verify_token) { echo $_GET['hub_challenge']; exit; }

// Obtain data sent by the webhook
$request_body = file_get_contents('php://input');
$data = json_decode($request_body, true);

// If we want to log the activity to a text file for debugging purposes
/*$fp = fopen('output_webhook.txt', 'w');
fwrite($fp, $request_body . "\r\n");
fclose($fp);*/

// Obtain recipient id from the webhook event data
$recipient = $data['entry'][0]['messaging'][0]['sender']['id'];
// Obtain message from the webhook event data
$received_text = $data['entry'][0]['messaging'][0]['message']['text'];

// We setup a curl to interact with the Workplace Messaging API
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL,"https://graph.facebook.com/v13.0/me/messages?access_token=" . $access_token);
curl_setopt($ch, CURLOPT_POST, 1);
curl_setopt( $ch, CURLOPT_HTTPHEADER, array('Content-Type:application/json'));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

// We send a mark as seen to the user who sent the message while we process it
// This action is optional
$fields = array(
	"sender_action" => "mark_seen",
	"recipient" => array("id" => $recipient)
 );
$fields_string = json_encode($fields);
curl_setopt($ch, CURLOPT_POSTFIELDS, $fields_string);
$server_output = curl_exec($ch); // We can optionally process the server output


// We compose a different response depending on the text that the user sent to the bot
if ("recognition" == $received_text) { // When the word recognition is received
	$fields = array(
		"message" => array("text" => "Hello! Thanks for using our recognition service. Let's share some love with the rest of the team. Who you want to nominate? Please give an email:"),
	    "recipient" => array("id" => $recipient),
	    "messaging_type" => "RESPONSE"
	);
} else if (strpos($received_text, '@') !== false) {
	$fields = array(
		"message" => array("text" => "Cool! We are sharing some love with " . $received_text . ". Can you tell us the reason?" , "quick_replies" => array(
            array(
                    "content_type" => "text",
                    "title" => "Build Social Value",
                    "payload" => "social_value",
                    "image_url" => "https://img.icons8.com/love-circled"
            ),
            array(
                    "content_type" => "text",
                    "title" => "Help in a Project",
                    "payload" => "help_project",
                    "image_url" => "https://img.icons8.com/project"
            ),
            array(
                    "content_type" => "text",
                    "title" => "Great Leadership",
                    "payload" => "leadership",
                    "image_url" => "https://img.icons8.com/leadership"
				)
        )),
		"recipient" => array("id" => $recipient),
		"messaging_type" => "RESPONSE"
    );
} else {
	if (isset($data['entry'][0]['messaging'][0]['message']['quick_reply']['payload'])) { // We check if a payload was received from the webhook, i.e. if any quick reply button was pushed
		$quick_reply = $data['entry'][0]['messaging'][0]['message']['quick_reply']['payload'];
		if ("social_value" == $quick_reply || "help_project" == $quick_reply || "leadership" == $quick_reply) {
            $fields = array(
                "message" => array("text" => "Thanks for sending your recognition. We will inform them and their manager. :)"),
                "recipient" => array("id" => $recipient),
                "messaging_type" => "RESPONSE"
            );
		}
	} else {
		$fields = array(
			"message" => array("text" => "Unfortunately I don't understand this command. Please try with other command."),
			"recipient" => array("id" => $recipient),
			"messaging_type" => "RESPONSE"
		);
	}
}

// We send the response to the Workplace API so the message can be delivered to the user
$fields_string = json_encode($fields);
curl_setopt($ch, CURLOPT_POSTFIELDS, $fields_string);
$server_output = curl_exec($ch);
curl_close ($ch);

// Further processing ...
if ($server_output == "OK") { echo "ALRIGHTY!"; } else { echo "NOPE. " . $server_output; }

?>