<?php
	if (
		!preg_match('/STEAM_\d:\d:\d+/', $_GET['steamID']) ||
		!preg_match('/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/', $_GET['ip'])
	) {
		http_response_code(400);
		exit;
	}

	function convertSteamID2ToSteamID64($steamID2) {
		$matches = array();
		preg_match('/STEAM_\d:(\d):(\d+)/', $steamID2, $matches);
		return $matches[2] * 2 + 76561197960265728 + $matches[1];
	}

    $config = array(
    	'steamID' => convertSteamID2ToSteamID64($_GET['steamID']),
        'steamKey' => ''
    );

    $GEO = json_decode(
    	file_get_contents(
    		sprintf(
    			'http://ip-api.com/json/%s?%s',
    			$_GET['ip'],
    			http_build_query(array(
    				'fields' => 16921,
    				'lang' => 'ru'
    				)
    			)
    		)
    	)
    , true);
    
    $steam = json_decode(
    	file_get_contents(
    		sprintf(
    			'http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=%s&steamids=%s',
    			$config['steamKey'],
    			$config['steamID']
    		)
    	),
    true)['response']['players'][0];

    if ($steam) {
        $steam = array(
            'status' => 'success',
            'name' => $steam['realname'],
            'vac' => json_decode(
            	file_get_contents(
            		sprintf(
            			'http://api.steampowered.com/ISteamUser/GetPlayerBans/v1/?key=%s&steamids=%s',
            			$config['steamKey'],
            			$config['steamID']
            		)
            	),
            true)['players'][0]['VACBanned']
        );
    } else {
        $steam = array(
        	'status' => 'fail'
        );
    }

    $response = array(
        'geo' => $GEO,
        'steam' => $steam
    );

    header('Content-Type: application/json');
    echo json_encode($response, JSON_NUMERIC_CHECK);
