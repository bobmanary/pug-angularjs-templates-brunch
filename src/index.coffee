escape = require('js-string-escape');
pug = require('pug')

module.exports = class AngularTemplatesCompiler
  brunchPlugin: yes
  type: 'template'
  extension: 'jade'

  _default_path_transform: (path) ->
    # Default path transformation is a no-op
    path

  constructor: (config) ->
    @module = config.plugins?.pug_angular_templates?.module or 'templates'
    @path_transform = config.plugins?.pug_angular_templates?.path_transform or @_default_path_transform
    @locals = config.plugins?.pug_angular_templates?.locals or {}
    @pretty = !!config.plugins?.pug_angular_templates?.pretty
    @doctype = config.plugins?.pug_angular_templates?.doctype or "5"


  compile: (data, path, callback) ->
    pugfunction = pug.compile data,
      debug: false
      pretty: @pretty
      doctype: @doctype
      filename: path
      compileDebug: false
    html = pugfunction @locals
    html = escape(html)
    url = @path_transform(path.replace(/\\/g, "/"))

    callback null, """
(function() {
    var module;

    try {
        // Get current templates module
        module = angular.module('#{@module}');
    } catch (error) {
        // Or create a new one
        module = angular.module('#{@module}', []);
    }

    module.run(["$templateCache", function($templateCache) {
        $templateCache.put('#{url}', '#{html}');
    }]);
})();
"""
