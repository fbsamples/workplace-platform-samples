var gulp = require('gulp');
var eslint= require('gulp-eslint');
var mocha = require('gulp-mocha');

var libs = ['lib/**/*.js', 'example/**/*.js'];
var tests = './test/*.js';

gulp.task('lint', function(){
    var src = libs.concat(tests);
    return gulp.src(src)
        .pipe(eslint())
        .pipe(eslint.format())
});

gulp.task('mocha', function () {
    return gulp.src(tests, { read: false })
        .pipe(mocha({
            globals: { env: require('./test/support/env') },
            reporter: 'spec'
        }));
});

gulp.task('build', ['lint', 'mocha']);
gulp.task('default', ['build']);

gulp.task('watch', function(){
    gulp.watch([libs, tests], ['build']);
});
