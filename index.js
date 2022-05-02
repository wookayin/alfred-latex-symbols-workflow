/*
 * Alfred LaTeX symbols workflow
 *
 * Written by Jongwook Choi (@wookayin)
 */

import alfy from 'alfy';
import yaml from 'js-yaml';
import fs from 'fs';
import crypto from 'crypto';
import {matchSorter} from 'match-sorter';
import Color from 'color';

// Detect alfred light/dark theme.
const iconColor = new Color(alfy.alfred.themeBackground || "white").isDark() ? 'white' : 'black';


function md5hash(s) {
  return crypto.createHash('md5').update(s).digest('hex');
}

// Collect symbols data.
var symbols_data = [
  // {command: ..., fontenc: ..., textmode: ..., mathmode: ...}
];
yaml.load(fs.readFileSync("./symbols.yaml")).map(function(s) {
  if (typeof s == 'string') {
    symbols_data.push({'command': s});
  }
  else { // dict. each key can be one of bothmodes/textmode/mathmode
    for(const [mode, modeargs] of Object.entries({
      textmode: {textmode: true, mathmode: false},
      mathmode: {textmode: false, mathmode: true},
      bothmodes: {textmode: true, mathmode: true}})) {
      if (s[mode]) {
        s[mode].map(t => symbols_data.push({
          ...{command: t, package: s['package'], fontenc: s['fontenc'] || null},
          ...modeargs  // override textmode/mathmode with the current context
        }));
      }
    }
  }
});
// Process id and filename.
symbols_data.map(function(s) {
  s.id = [
    s.package ? s.package : 'latex2e',
    s.fontenc ? s.fontenc : 'OT1',
    s.command.replace('\\', '_'),
  ].join('-');
  s['filename'] = 'symbol' + md5hash(s.id);
});


// Search
const query = function() {
  if (!alfy.input) {
    // console.log(symbols_data.slice(30, 40));  // DEBUG
    return [];
  }

  var results = alfy
    .matches(alfy.input, symbols_data, 'command');

  results = matchSorter(results, '\\' + alfy.input, {keys: ['command']})
  //console.log(results);

  return results.map(v => ({
    title: v.command,
    subtitle: [
      v.package ? ("Package " + v.package) : '',
      v.mathmode ? "(math mode)" : '',
    ].join(' '),
    icon: {
      path: `icons/${iconColor}/${v.filename}.png`,
    },
    arg: v.command,
  }));
};

alfy.output(query());
