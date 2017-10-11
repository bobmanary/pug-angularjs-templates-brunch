escape = require('js-string-escape');
pug = require('pug')

module.exports = class AngularTemplatesCompiler
  brunchPlugin: yes
  type: 'template'
  extension: 'pug'
  pattern: /\.(jade|pug)/

  _default_path_transform: (path) ->
    # Default path transformation is a no-op
    path

  constructor: (config) ->
    @module = config.plugins?.pug_angular_templates?.module or 'templates'
    @path_transform = config.plugins?.pug_angular_templates?.path_transform or @_default_path_transform
    @locals = config.plugins?.pug_angular_templates?.locals or {}
    @pretty = !!config.plugins?.pug_angular_templates?.pretty
    @doctype = config.plugins?.pug_angular_templates?.doctype or "5"
    @exportCachedTemplate = if (ngCache = config.plugins?.pug_angular_templates?.exportCachedTemplate)? then !!ngCache else true
    @exportCommonJs = !!config.plugins?.pug_angular_templates?.exportCommonJs

  compile: (data, path, callback) ->
    pugfunction = pug.compile data,
      debug: false
      pretty: @pretty
      doctype: @doctype
      filename: path
      compileDebug: false

    html = escape pugfunction @locals
    url = @path_transform(path.replace(/\\/g, "/"))

    callback null, """
      (function() {
        var ngModule, template = '#{html}';
        #{@insertExports(url, html)}
      })();
    """

  insertExports: (url, html) ->
    compiledExports = []
    if @exportCachedTemplate
      compiledExports.push """
        try {
          // Get current templates module
          ngModule = angular.module('#{@module}');
        } catch (error) {
          // Or create a new one
          ngModule = angular.module('#{@module}', []);
        }
        ngModule.run(["$templateCache", function($templateCache) {
          $templateCache.put('#{url}', template);
        }]);
      """

    if @exportCommonJs
      compiledExports.push """
        if (module) {
          module.exports = template;
        }
      """

    return compiledExports.join("\n")
