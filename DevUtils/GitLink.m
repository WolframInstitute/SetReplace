Package["SetReplaceDevUtils`"]

PackageImport["GeneralUtilities`"]

PackageExport["$GitLinkAvailableQ"]
PackageExport["GitSHAWithDirtyStar"]
PackageExport["InstallGitLink"]
PackageExport["CalculateMinorVersionNumber"]

SetUsage @ "
$GitLinkAvailableQ gets GitLink`, yields True in case of success and False otherwise.
";

(* unfortunately, owing to a bug in GitLink, GitLink *needs* to be on the $ContextPath or GitRepo objects
end up in the wrong context, since they are generated in a loopback link unqualified *)
$GitLinkAvailableQ := !FailureQ[Quiet @ Check[Needs["GitLink`"], $Failed]];

SyntaxInformation[GitSHAWithDirtyStar] = {"ArgumentsPattern" -> {repositoryDirectory_}};

FE`Evaluate[FEPrivate`AddSpecialArgCompletion["GitSHAWithDirtyStar" -> {2}]];

SetUsage @ "
GitSHAWithDirtyStar['repositoryDirectory$'] returns the SHA hash of the commit that is currently checked on \
for the Git repository at 'repositoryDirectory$'. Unlike the GitSHA function, this will include a '*' character \
if the current working tree is dirty.
";

GitSHAWithDirtyStar[repositoryDirectory_] /; TrueQ[$GitLinkAvailableQ] := ModuleScope[
  repo = GitLink`GitOpen[repositoryDirectory];
  sha = GitLink`GitSHA[repo, repo["HEAD"]];
  cleanQ = AllTrue[# === {} &] @ GitLink`GitStatus[repo];
  If[cleanQ, sha, sha <> "*"]
];

GitSHAWithDirtyStar[_] /; FalseQ[$GitLinkAvailableQ] := "NotAvailable";

SyntaxInformation[InstallGitLink] = {"ArgumentsPattern" -> {}};

SetUsage @ "
InstallGitLink[] will attempt to install GitLink on the current system (if necessary).
";

InstallGitLink[] := ModuleScope[
  If[PacletFind["GitLink", "Internal" -> All] =!= {}, Return[True]];
  
  (* Try multiple installation methods *)
  result = Quiet[
    PacletInstall["GitLink"], (* Try direct installation first *)
    {PacletInstall::notavail}
  ];
  If[!FailureQ[result], Return[True]];
  
  result = Quiet[
    PacletInstall["Wolfram/GitLink"], (* Try with Wolfram prefix *)
    {PacletInstall::notavail}
  ];
  If[!FailureQ[result], Return[True]];
  
  (* If all installation attempts fail, return False but don't error *)
  False
];

SyntaxInformation[CalculateMinorVersionNumber] = {"ArgumentsPattern" -> {repositoryDirectory_, masterBranch_}};

FE`Evaluate[FEPrivate`AddSpecialArgCompletion["GitSHAWithDirtyStar" -> {2, {"master", "main"}}]];

SetUsage @ "
CalculateMinorVersionNumber[repositoryDirectory$, masterBranch$] will calculate a minor version \
derived from the number of commits between the last checkpoint and the masterBranch$. \
The checkpoint is defined in scripts/version.wl.
";

CalculateMinorVersionNumber[repositoryDirectory_, masterBranch_] := ModuleScope[
  versionInformation = Import[FileNameJoin[{repositoryDirectory, "scripts", "version.wl"}]];
  gitRepo = GitLink`GitOpen[repositoryDirectory];
  If[$internalBuildQ, GitLink`GitFetch[gitRepo, "origin"]];
  minorVersionNumber = Max[0, Length[GitLink`GitRange[
    gitRepo,
    Except[versionInformation["Checkpoint"]],
    GitLink`GitMergeBase[gitRepo, "HEAD", masterBranch]]] - 1];
  minorVersionNumber
];
