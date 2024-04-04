open Printf

let param_template =
  (* Sample item used to populate the template config file *)
  {
    Config_v.name = "foo";
    key = "0123456789abcdef"
  }

let config_template =
  (*
    Records can be conveniently created using functions generated by
    "atdgen -v".
    Here we use Config_v.create_config to create a record of type
    Config_t.config. The big advantage over creating the record 
    directly using the record notation {...} is that we don't have to
    specify default values (such as timeout in this example).
  *)
  Config_v.create_config ~title:"" ~credentials: [param_template] ()

let make_json_template () =
  (* Thanks to the -j-defaults flag passed to atdgen, even default
     fields will be printed out *)
  let compact_json = Config_j.string_of_config config_template in
  Yojson.Safe.prettify compact_json

let print_template () =
  print_endline (make_json_template ())

let print_format () =
  print_string Config_atd.contents

let validate fname =
  let x =
    try
      (* Read config data structure from JSON file *)
      let x = Atdgen_runtime.Util.Json.from_file Config_j.read_config fname in
      (* Call the validators specified by <ocaml valid=...> *)
      match Config_v.validate_config [] x with
      | Some _ -> failwith "Some fields are invalid"
      | None -> x
    with e ->
      (* Print decent error message and exit *)
      let msg =
        match e with
            Failure s
          | Yojson.Json_error s -> s
          | e -> Printexc.to_string e
      in
      eprintf "Error: %s\n%!" msg;
      exit 1
  in
  (* Convert config to compact JSON and pretty-print it.
     ~std:true means that the output will not use extended syntax for
     variants and tuples but only standard JSON. *)
  let json = Yojson.Safe.prettify ~std:true (Config_j.string_of_config x) in
  print_endline json

type action = Template | Format | Validate of string

let main () =
  let action = ref Template in
  let options = [
    "-template", Arg.Unit (fun () -> action := Template),
    "
          prints a sample configuration file";

    "-format", Arg.Unit (fun () -> action := Format),
    "
          prints the format specification of the config files (atd format)";

    "-validate", Arg.String (fun s -> action := Validate s),
    "<CONFIG FILE>
          reads a config file, validates it, adds default values
          and prints the config nicely to stdout";
  ]
  in
  let usage_msg = sprintf "\
Usage: %s [-template|-format|-validate ...]
Demonstration of how to manage JSON configuration files with atdgen.
"
    Sys.argv.(0)
  in
  let anon_fun s = eprintf "Invalid command parameter %S\n%!" s; exit 1 in
  Arg.parse options anon_fun usage_msg;

  match !action with
      Template -> print_template ()
    | Format -> print_format ()
    | Validate s -> validate s

let () = main ()
