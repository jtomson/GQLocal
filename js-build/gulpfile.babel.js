import gulp from 'gulp';
import browserify from 'gulp-browserify';
import rename from 'gulp-rename';

// Default Task
gulp.task('default', ['js']);

// JS compilation
gulp.task('js', () => {
  gulp.src('index.js')
    .pipe(browserify({
      transform: ['babelify']
    }))
    .pipe(rename('bundle.js'))
    .pipe(gulp.dest('./build/js'))
});
