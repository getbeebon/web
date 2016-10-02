gulp = require 'gulp'
coffee = require 'gulp-coffee'

gulp.task 'default', () ->
  gulp.src ['**/*.coffee', '!gulpfile.coffee', '!bower_components/**/*',
            '!node_modules/**/*',]
  .pipe coffee()
  .pipe gulp.dest './'

gulp.task 'watch',()->
  gulp.watch '**/*.coffee', ['default']