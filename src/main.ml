open GapiLens.Infix
open GapiCalendarV3Model
open GapiCalendarV3Service
open Howm

let group = new Config_file.group
let client_id_cp = new Config_file.string_cp ~group ["client_id"] "" ""
let client_secret_cp = new Config_file.string_cp ~group ["client_secret"] "" ""
let redirect_uri_cp = new Config_file.string_cp ~group ["redirect_uri"] "" ""
let access_token_cp = new Config_file.string_cp ~group ["access_token"] "" ""
let refresh_token_cp = new Config_file.string_cp ~group ["refresh_token"] "" ""

let do_request interact = 
  let state = GapiCurl.global_init () in
  GapiConversation.with_session
    GapiConfig.default
    state
    interact;
  GapiCurl.global_cleanup state |> ignore



let authorize () =
  let url = GapiOAuth2.authorization_code_url
    ~redirect_uri: redirect_uri_cp#get
    ~response_type: "code"
    ~scope: [GapiCalendarV3Service.Scope.calendar]
    client_id_cp#get in 
  print_endline url;

  let code = read_line () in 
  do_request (fun session ->
    let (response, _) = GapiOAuth2.get_access_token
      ~client_id: client_id_cp#get
      ~client_secret: client_secret_cp#get
      ~code
      ~redirect_uri: redirect_uri_cp#get
      session in
    let { GapiAuthResponse.OAuth2.access_token;
	  token_type;
	  expires_in;
	  refresh_token } = response
		 |. GapiAuthResponse.oauth2_access_token
		 |. GapiLens.option_get in
    access_token_cp#set access_token;
    refresh_token_cp#set refresh_token;
    group#write "./config.txt");;

let refresh session = 
  let (response, session) = GapiOAuth2.refresh_access_token
    client_id_cp#get
    client_secret_cp#get
    refresh_token_cp#get
    session in
  let { GapiAuthResponse.OAuth2.access_token;
	refresh_token;
	token_type;
	expires_in
      } = response |. GapiAuthResponse.oauth2_access_token |. GapiLens.option_get in
  access_token_cp#set access_token;
  refresh_token_cp#set refresh_token;
  group#write "./config.txt";
  session |> GapiConversation.Session.auth ^= GapiConversation.Session.OAuth2 { 
    GapiConversation.Session.oauth2_token = access_token; 
    refresh_token 
  }

let register_event = function
  | { Howm.date = None; title; content; flag } -> ()
  | { Howm.date = (Some d); title; content; flag } as event -> 
    let config = { GapiConfig.default with
      GapiConfig.application_name = "howm-gcal-sync";
      GapiConfig.auth = GapiConfig.OAuth2 { GapiConfig.client_id = client_id_cp#get;
    					    GapiConfig.client_secret = client_secret_cp#get;
    					    GapiConfig.refresh_access_token = None } } in
    let auth_context = GapiConversation.Session.OAuth2
      { GapiConversation.Session.oauth2_token = access_token_cp#get;
    	GapiConversation.Session.refresh_token = refresh_token_cp#get } in
    GapiConversation.with_session ~auth_context config GapiCurl.Initialized (fun session ->
      let end_date = (Netdate.since_epoch d) +. 24.0 *. 3600.0 in
      let event = {
    	Event.empty with
    	  Event.summary = title;
    	  Event.location = "";
    	  Event.attendees = [];
    	  Event.iCalUID = Howm.string_of_event event;
    	  Event.start = { EventDateTime.empty with EventDateTime.dateTime = d };
    	  Event._end  = { EventDateTime.empty with EventDateTime.dateTime = Netdate.create end_date };
	  Event.description = !content
      } in
      try EventsResource.insert ~calendarId:"primary" event session |> ignore
      with
    	GapiService.ServiceError { GapiError.RequestError.errors; code; message } -> print_endline message
    )
      

let () =
  group#read "./config.txt";
  if access_token_cp#get = "" || refresh_token_cp#get = "" then 
    authorize ()
  else
    Howm.listFiles "/Users/cormo/Dropbox/howm" 
    |> List.map Howm.read_file
    |> List.concat
    |> List.filter (fun e -> e.Howm.flag = Some "@" || e.Howm.flag = Some "!")
    |> List.filter (fun e -> 
      match e.Howm.date with 
      | Some d -> 
	let today0 = { (Netdate.create (Unix.time())) with 
	  Netdate.hour = 0;
	  minute = 0;
	  second = 0;
	  nanos  = 0
	} in 
	Netdate.since_epoch d >= Netdate.since_epoch today0
      | None -> false)
    |> List.map register_event
    |> ignore
