module Howm = struct
  type t = { date: Netdate.t option;
	     title: string;
	     content: string ref;
	     flag: string option
	   }

  let string_of_event { date; title; content; flag } = 
    match (date, flag) with
    | Some d, Some f -> Netdate.format "[%F]" d ^ " " ^ title ^ !content
    | _, _ -> title ^ !content
    
  let listFiles root =
    let years = Sys.readdir root 
      |> Array.to_list 
      |> List.map (fun y -> root ^ "/" ^ y)
      |> List.filter Sys.is_directory in
    let months = years 
      |> List.map (fun y -> 
	Sys.readdir y |> Array.to_list
		      |> List.map (fun m -> y ^ "/" ^ m)
		      |> List.filter Sys.is_directory)
      |> List.concat in
    months 
    |> List.map (fun m ->
      let pattern = Str.regexp ".*\\.howm$" in
      Sys.readdir m |> Array.to_list
		    |> List.map (fun path -> m ^ "/" ^ path)
		    |> List.filter (fun path -> Str.string_match pattern path 0))
    |> List.concat

  let read_file path =
    let in_ch = open_in path in
    let lines = Std.input_list in_ch in
    let make_title(date, flag, title) = { date; flag; title; content = ref "" } in
    let title_pat = Str.regexp "^= \\(.*\\)$" in
    let end_pat = Str.regexp "^\\[[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]\\].*$" in
    let date_title_pat = 
      Str.regexp "^= \\[\\([0-9][0-9][0-9][0-9]\\)-\\([0-9][0-9]\\)-\\([0-9][0-9]\\)\\]\\(.\\) \\(.*\\)$" in
    let readWhile events line = 
      if Str.string_match title_pat line 0 then
	if Str.string_match date_title_pat line 0 then 
	  let year  = Str.matched_group 1 line |> int_of_string in
	  let month = Str.matched_group 2 line |> int_of_string in
	  let day   = Str.matched_group 3 line |> int_of_string in
	  let flag  = Str.matched_group 4 line in
	  let title = Str.matched_group 5 line in
	  let date  = { Netdate.year; month; day; hour = 0; minute = 0; second = 0;
			nanos = 0; zone = 9*60; week_day = -1 } in	
	  make_title(Some date,Some flag, title)::events
	else begin
	  Str.string_match title_pat line 0 |> ignore;
	  let title = Str.matched_group 1 line in
	  make_title(None, None, title)::events
	end 
      else if Str.string_match end_pat line 0 then
	events
      else begin 
	begin match events with 
	| e::es ->
	  let content = e.content in
	  content := !content ^ "\n" ^ line
	| _ -> ()
	end ;
	events
      end in
  let events = List.fold_left readWhile [] lines in
  close_in in_ch;
  events
end
			  
	  
