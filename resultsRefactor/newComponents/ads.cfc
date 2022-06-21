component accessors=true output=false persistent=false {

    property type="number" name="adsPerPage" default="6";
    property type="string" name="state" default="FL";

    public function init(string state = variables.state, number adsPerPage = variables.adsPerPage) {
        setState(arguments.state);
        setAdsPerPage(arguments.adsPerPage);
    }


    public function getAds(string state = variables.state) {
        adsQuery = getAdsQuery(arguments.state);
        adPool = getAdPool(adsQuery);
        pageAds = createAds(adPool);
        return pageAds;
    }


    private query function getAdsQuery(required string state) {
        if(state != "DC") {
            adsQuery = queryExecute(
                "SELECT DISTINCT MAILFILE_ID, COMPANY, CITY, STATE, AD_SIZE
    			FROM CUSTOMERS
    			WHERE PRIORITY = 'COMPLETED' AND STATUS = 'ACTIVE'
                    AND STATE = :state",
                { state = arguments.state },
                {datasource="memory"});
        } else {
            adsQuery = queryExecute(
                "SELECT DISTINCT MAILFILE_ID, COMPANY, CITY, STATE, AD_SIZE
    			FROM CUSTOMERS
    			WHERE PRIORITY = 'COMPLETED' AND STATUS = 'ACTIVE'",
                {},
                {datasource="memory"});
        }
        return adsQuery;
    }


    private array function getAdPool(required query adsQuery) {
        adPool = [];
        for(row in arguments.adsQuery) {
            leaderboard = getLeaderboardPath(row.MAILFILE_ID, row.AD_SIZE, "local");
            skyline = getSkylinePath(row.MAILFILE_ID, row.AD_SIZE, "local");
            // standard = "";
            // smallSquare = "";

            if(fileExists(leaderboard) AND fileExists(skyline)) {
                adPool.append(row.MAILFILE_ID);
            }
        }
        createObject("java", "java.util.Collections").Shuffle(adPool)
        return adPool;
    }


    private string function formatRegion(required string region) {
        if(arguments.region == "CA") {
            return "WC";
        } else {
            return arguments.region
        }
    }


    private string function getLeaderboardPath(required string mailfile_id, required string size, string type = "live") {
        region = trim(formatRegion(left(arguments.mailfile_id, 2)));
        cycle = trim(mid(arguments.mailfile_id, 8, 2));
        adSize = trim(arguments.size);
        if(arguments.type == "local") {
            return "c:\inetpub\wwwroot\graphics65wr\client_ads2_leaderboard\#region#\#cycle#\#adSize#\jpg\#adSize#_#arguments.mailfile_id#_leaderboard.jpg";
        } else if(arguments.type == "live") {
            return "https://images.originalyellow.com/client_ads2_leaderboard/#region#/#cycle#/#adSize#/jpg/#adSize#_#arguments.mailfile_id#_leaderboard.jpg";
        } else {
            return ""
        }
    }


    private string function getSkylinePath(required string mailfile_id, required string size, string type = "live") {
        region = trim(formatRegion(left(arguments.mailfile_id, 2)));
        cycle = trim(mid(arguments.mailfile_id, 8, 2));
        adSize = trim(arguments.size);
        if(arguments.type == "local") {
            return "c:\inetpub\wwwroot\graphics65wr\client_ads2_skyline\#region#\#cycle#\#adSize#\jpg\#adSize#_#arguments.Mailfile_ID#_skyline.jpg";
        } else if(arguments.type == "live") {
            return "https://images.originalyellow.com/client_ads2_skyline/#region#/#cycle#/#adSize#/jpg/#adSize#_#arguments.Mailfile_ID#_skyline.jpg";
        } else {
            return "";
        }
    }


    private string function getStandardPath(required string mailfile_id, required string size, string type = "live") {
        region = trim(formatRegion(left(arguments.mailfile_id, 2)));
        cycle = trim(mid(arguments.mailfile_id, 8, 2));
        adSize = trim(arguments.size);
        if(arguments.type == "local") {
            return "c:\inetpub\wwwroot\graphics65wr\#adSize#_#arguments.Mailfile_ID#.jpg";
        } else if(arguments.type == "live") {
            return "https://images.originalyellow.com/#adSize#_#arguments.Mailfile_ID#.jpg";
        } else {
            return "";
        }
    }


    private array function createAds(required array adPool) {
        pageAds = [];
        try {
            for(i = 1; i <= variables.adsPerPage; i++) {
                mailfile_id = adPool[i];
                data = getAdData(mailfile_id);
                adObject = {
                    "info" = {
                        "MAILFILE_ID" = data.MAILFILE_ID,
                        "ID" = data.ID,
                        "COMPANY" = data.COMPANY,
                        "ADDRESS" = data.ADDRESS1,
                        "CITY" = data.CITY,
                        "STATE" = data.STATE,
                        "ZIP" = data.ZIP,
                        "PHONE" = data.PHONE,
                        "CLASSIFICATION" = data.CLASSIFICATION_1,
                        "SPECIALTY" = data.SPECIALTY,
                        "WEBSITE" = data.WEBADDR
                    },
                    "leaderboard" = getLeaderboardPath(data.MAILFILE_ID, data.AD_SIZE),
                    "skyline" = getSkylinePath(data.MAILFILE_ID, data.AD_SIZE),
                    "standard" = getStandardPath(data.MAILFILE_ID, data.AD_SIZE)
                };
                pageAds.append(adObject);
            }
        } catch(any e) {
            // debug
        }
        return pageAds;
    }


    private query function getAdData(required string mailfile_id) {
        adDataQuery = queryExecute(
            "SELECT TOP 1 MAILFILE_ID, ID, COMPANY, ADDRESS1, CITY, STATE, ZIP, PHONE, CLASSIFICATION_1, SPECIALTY, WEBADDR, AD_SIZE FROM WEBMASTERDB
            WHERE MAILFILE_ID = :id",
            {id = arguments.mailfile_id},
            {datasource = "memory"});
        return adDataQuery;
    }


}
