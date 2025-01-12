#!/usr/bin/env wolframscript

Check[
  Get[FileNameJoin[{DirectoryName[$InputFileName], "DevUtils", "init.m"}]];
  Off[General::stop];
,
  Print["Message occurred during loading of DevUtils. Build failed."];
  Exit[1];
];

Check[
  (* Try to install GitLink but don't fail if it doesn't work *)
  If[!InstallGitLink[],
    Print["Note: GitLink installation failed. Will continue without Git versioning."]
  ];

  buildResult = BuildLibSetReplace["Verbose" -> True];
  If[!AssociationQ[buildResult],
    Print["Build failed: ", buildResult];
    Exit[1]
  ];

  packResult = PackSetReplace["Verbose" -> True];
  pacletLocation = packResult["Location"];
  If[!StringQ[pacletLocation],
    Print["Pack failed: ", pacletLocation];
    Exit[1]
  ];

  previousPaclets = PacletFind["SetReplace"];
  If[previousPaclets =!= {},
    Print["Uninstalling previous SetReplace at ", First[previousPaclets]["Location"]];
    If[FailureQ[PacletUninstall["SetReplace"]],
      Print["Could not uninstall old paclet."];
      Exit[1];
    ];
  ];

  Print["Installing paclet at ", pacletLocation];
  installedPaclet = PacletInstall[pacletLocation];
  If[FailureQ[installedPaclet],
    Print["Could not install new paclet: ", installedPaclet];
    Exit[1];
  ];

  Print["Paclet installed to ", installedPaclet["Location"]];
,
  Print["Message occurred during installing. Install failed."];
  Print["$MessageList = ", $MessageList];
  Exit[1];
];

Print["Install succeeded."];
Exit[0];
