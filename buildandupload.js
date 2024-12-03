const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
    
var settings = fs.readFileSync("buildsettings.json", "utf-8");
settings = JSON.parse(settings);
run();

async function run() {
  var newBuild = settings.newBuild;
  var newVersion = settings.newVersion;

  if (newBuild === undefined) {
    newBuild = settings.build + 1;
  }
  var constantsFile = fs.readFileSync(__dirname + settings.constantsFile, "utf-8");

  var searchBuild = `let BUILD = "${settings.build}"`;
  var replaceBuild = `let BUILD = "${newBuild}"`;

  constantsFile = constantsFile.replace(searchBuild, replaceBuild);

  if (newVersion !== undefined) {
    var searchVersion = `let VERSION = "${settings.version}"`;
    var replaceVersion = `let VERSION = "${newVersion}"`;
    constantsFile = constantsFile.replace(searchVersion, replaceVersion);
    console.log(`updated constants file from version ${settings.version} to version ${newVersion}`);
  }
  fs.writeFileSync(__dirname + settings.constantsFile, constantsFile, "utf-8");
  console.log(`updated constants file from build ${settings.build} to build ${newBuild}`);

  var projectFile = fs.readFileSync(__dirname + settings.projectFile, "utf-8");

  searchBuild = `CURRENT_PROJECT_VERSION = ${settings.build};`;
  replaceBuild = `CURRENT_PROJECT_VERSION = ${newBuild};`;

  projectFile = projectFile.replaceAll(searchBuild, replaceBuild);

  if (newVersion !== undefined) {
    searchVersion = `MARKETING_VERSION = ${settings.version};`;
    replaceVersion = `MARKETING_VERSION = ${newVersion};`;
    projectFile = projectFile.replaceAll(searchVersion, replaceVersion);
    console.log(`updated project settings file from version ${settings.version} to version ${newVersion}`);
  }

  fs.writeFileSync(__dirname + settings.projectFile, projectFile, "utf-8");
  console.log("updated project settings file");

  settings.build = newBuild;
  if (newVersion !== undefined) {
    settings.version = newVersion;
  }

  fs.writeFileSync("buildsettings.json", JSON.stringify(settings), "utf-8");
  console.log("updated buildsettings.json file");

  await gitCommit();
  await gitPush();
  console.log("changes send to git;")
  
  console.log("starting build");
  checkBuildFolder();
  await buildArchive();
  console.log("build has completed");
  console.log("starting upload")
  await uploadArchive();
  console.log("upload has completed");
}

function checkBuildFolder() {
  const folderPath = './build';

  if (!fs.existsSync(folderPath)) {
    fs.mkdirSync(folderPath);
  }
}

async function executeShell(command) {
  return new Promise(function (resolve, reject) {
    const child = exec(command, (error, stdout, stderr) => {
      if (error) {
        console.error(`Error: ${error.message}`);
        return;
      }
      if (stderr) {
        console.error(`stderr: ${stderr}`);
        return;
      }
      console.log(`stdout: ${stdout}`);
    });

    child.on('exit', (code, signal) => {
      console.log(`child process exited with code ${code} and signal ${signal}`);
      resolve()
    });
  })
}

async function gitCommit() {
  const command = `git commit -a -m "auto rebuild and upload"`;

  await executeShell(command);
}

async function gitPush() {
  const command = `git push`;

  await executeShell(command);
}

async function buildArchive() {
  const workspacePath = path.join(__dirname, settings.workspaceFile);
  const command = `xcodebuild -workspace "${workspacePath}" -scheme "${settings.scheme}" -configuration "Release" -sdk iphoneos archive -archivePath "${__dirname}/build/${settings.archiveFile}"`;

  await executeShell(command);
}

async function uploadArchive() {
  const workspacePath = path.join(__dirname, settings.workspaceFile);
  const command = `xcodebuild -exportArchive -archivePath "${__dirname}/build/${settings.archiveFile}" -exportOptionsPlist exportOptions.plist -exportPath "${__dirname}/build" `;

  await executeShell(command);
}


// get schemas
// xcodebuild -list -project <NAME>.xcodeproj/
// build
//xcodebuild -workspace MyToDo.xcworkspace -scheme "My To Do" -configuration "Release" -sdk iphoneos archive -archivePath ${PWD}/build/MyToDo.archive
// upload
//xcodebuild -exportArchive -archivePath ${PWD}/build/MyToDo.archive.xcarchive -exportOptionsPlist exportOptions.plist -exportPath ${PWD}/build
