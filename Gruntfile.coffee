coffee_src = "src/*.coffee"
module.exports = (grunt) ->
    grunt.initConfig

        # grunt coffee
        coffee:
          compile:
            expand: true
            cwd: 'src'
            src: ['**/*.coffee']
            dest: 'static'
            ext: '.js'
            options:
              bare: true
              preserve_dirs: true
     
        # grunt watch (or simply grunt)
        watch:
          coffee:
            files: '<%= coffee.compile.src %>'
            tasks: ['coffee']
          options:
            livereload:true

    grunt.loadNpmTasks "grunt-contrib-coffee"
    grunt.loadNpmTasks "grunt-contrib-watch"
    grunt.loadNpmTasks "grunt-notify"
    grunt.loadNpmTasks "grunt-available-tasks"
    grunt.loadNpmTasks "grunt-string-replace"
    grunt.loadNpmTasks "grunt-contrib-compress"

    grunt.registerTask "default", [
        "watch"
    ]