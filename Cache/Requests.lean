/-
Copyright (c) 2023 Arthur Paulino. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Arthur Paulino
-/
import Lean.Data.Json.Parser
import Cache.Hashing

namespace Cache.Requests

/-- Azure blob URL -/
def URL : String :=
  "https://lakecache.blob.core.windows.net/mathlib4"

open System (FilePath)

/--
Given a file name like `"1234.tar.gz"`, makes the URL to that file on the server.

The `f/` prefix means that it's a common file for caching.
-/
def mkFileURL (fileName : String) (token : Option String) : IO String :=
  return match token with
  | some token => s!"{URL}/f/{fileName}?{token}"
  | none => s!"{URL}/f/{fileName}"

section Get

/-- Formats the config file for `curl`, containing the list of files to be downloaded -/
def mkGetConfigContent (hashMap : IO.HashMap) : IO String := do
  let l ← hashMap.foldM (init := []) fun acc _ hash => do
    let fileName := hash.asTarGz
    pure $ (s!"url = {← mkFileURL fileName none}\n-o {IO.CACHEDIR / fileName}") :: acc
  return "\n".intercalate l

/-- Calls `curl` to download a single file from the server to `CACHEDIR` (`.cache`) -/
def downloadFile (hash : UInt64) : IO Bool := do
  let fileName := hash.asTarGz
  let url ← mkFileURL fileName none
  let path := IO.CACHEDIR / fileName
  let out ← IO.Process.output
    { cmd := (← IO.getCurl), args := #[url, "--fail", "--silent", "-o", path.toString] }
  if out.exitCode = 0 then
    pure true
  else
    IO.FS.removeFile path
    pure false

/-- Calls `curl` to download files from the server to `CACHEDIR` (`.cache`) -/
def downloadFiles (hashMap : IO.HashMap) (forceDownload : Bool) (parallel : Bool) : IO Unit := do
  let hashMap := if forceDownload then hashMap else hashMap.filter (← IO.getLocalCacheSet) false
  let size := hashMap.size
  if size > 0 then
    IO.mkDir IO.CACHEDIR
    IO.println s!"Attempting to download {size} file(s)"
    let mut failed := 0
    if parallel then
      IO.FS.writeFile IO.CURLCFG (← mkGetConfigContent hashMap)
      let out ← IO.runCurl
        #["--request", "GET", "--parallel", "--fail", "--silent",
          "--write-out", "%{json}\n", "--config", IO.CURLCFG.toString] false
      IO.FS.removeFile IO.CURLCFG
      -- output errors other than 404 and remove corresponding partial downloads
      for line in out.splitOn "\n" |>.filter (!·.isEmpty) do
        let result ← IO.ofExcept <| Lean.Json.parse line.trim
        if !(result.getObjValAs? Nat "http_code" matches .ok 200 | .ok 404) then
          failed := failed + 1
          if let .ok e := result.getObjValAs? String "errormsg" then
            IO.println e
          -- `curl --remove-on-error` can already do this, but only from 7.83 onwards
          if let .ok fn := result.getObjValAs? String "filename_effective" then
            if (← System.FilePath.pathExists fn) then
              IO.FS.removeFile fn
    else
      let r ← hashMap.foldM (init := []) fun acc _ hash => do
        pure <| (← IO.asTask do downloadFile hash) :: acc
      failed := r.foldl (init := 0) fun f t => if let .ok true := t.get then f else f + 1
    if failed > 0 then
      IO.println s!"{failed} download(s) failed"
      IO.Process.exit 1
  else IO.println "No files to download"

/-- Downloads missing files, and unpacks files. -/
def getFiles (hashMap : IO.HashMap) (forceDownload : Bool) (parallel : Bool) : IO Unit := do
  downloadFiles hashMap forceDownload parallel
  IO.unpackCache hashMap

end Get

section Put

/-- Formats the config file for `curl`, containing the list of files to be uploades -/
def mkPutConfigContent (fileNames : Array String) (token : String) : IO String := do
  let l ← fileNames.data.mapM fun fileName : String => do
    pure s!"-T {(IO.CACHEDIR / fileName).toString}\nurl = {← mkFileURL fileName (some token)}"
  return "\n".intercalate l

/-- Calls `curl` to send a set of cached files to the server -/
def putFiles (fileNames : Array String) (overwrite : Bool) (token : String) : IO Unit := do
  let size := fileNames.size
  if size > 0 then
    IO.FS.writeFile IO.CURLCFG (← mkPutConfigContent fileNames token)
    IO.println s!"Attempting to upload {size} file(s)"
    if overwrite then
      discard $ IO.runCurl #["-X", "PUT", "-H", "x-ms-blob-type: BlockBlob", "--parallel",
        "-K", IO.CURLCFG.toString]
    else
      discard $ IO.runCurl #["-X", "PUT", "-H", "x-ms-blob-type: BlockBlob",
        "-H", "If-None-Match: *", "--parallel", "-K", IO.CURLCFG.toString]
    IO.FS.removeFile IO.CURLCFG
  else IO.println "No files to upload"

end Put

section Commit

def isGitStatusClean : IO Bool :=
  return (← IO.runCmd "git" #["status", "--porcelain"]).isEmpty

def getGitCommitHash : IO String := do
  let ret := (← IO.runCmd "git" #["log", "-1"]).replace "\n" " "
  match ret.splitOn " " with
  | "commit" :: hash :: _ => return hash
  | _ => throw $ IO.userError "Invalid format for the return of `git log -1`"

/--
Sends a commit file to the server, containing the hashes of the respective commited files.

The file name is the current Git hash and the `c/` prefix means that it's a commit file.
-/
def commit (hashMap : IO.HashMap) (overwrite : Bool) (token : String) : IO Unit := do
  let hash ← getGitCommitHash
  let path := IO.CACHEDIR / hash
  IO.mkDir IO.CACHEDIR
  IO.FS.writeFile path $ ("\n".intercalate $ hashMap.hashes.toList.map toString) ++ "\n"
  let params := if overwrite
    then #["-X", "PUT", "-H", "x-ms-blob-type: BlockBlob"]
    else #["-X", "PUT", "-H", "x-ms-blob-type: BlockBlob", "-H", "If-None-Match: *"]
  discard $ IO.runCurl $ params ++ #["-T", path.toString, s!"{URL}/c/{hash}?{token}"]
  IO.FS.removeFile path

end Commit

section Collect

inductive QueryType
  | files | commits | all

def QueryType.prefix : QueryType → String
  | files   => "&prefix=f/"
  | commits => "&prefix=c/"
  | all     => default

def formatError : IO α :=
  throw $ IO.userError "Invalid format for curl return"

def QueryType.desc : QueryType → String
  | files   => "hosted files"
  | commits => "hosted commits"
  | all     => "everything"

/--
Retrieves metadata about hosted files: their names and the timestamps of last modification.

Example: `["f/39476538726384726.tar.gz", "Sat, 24 Dec 2022 17:33:01 GMT"]`
-/
def getFilesInfo (q : QueryType) : IO $ List (String × String) := do
  IO.println s!"Downloading info list of {q.desc}"
  let ret ← IO.runCurl #["-X", "GET", s!"{URL}?comp=list&restype=container{q.prefix}"]
  match ret.splitOn "<Name>" with
  | [] => formatError
  | [_] => return default
  | _ :: parts =>
    parts.mapM fun part => match part.splitOn "</Name>" with
      | [name, rest] => match rest.splitOn "<Last-Modified>" with
        | [_, rest] => match rest.splitOn "</Last-Modified>" with
          | [date, _] => pure (name, date)
          | _ => formatError
        | _ => formatError
      | _ => formatError

end Collect

end Cache.Requests
