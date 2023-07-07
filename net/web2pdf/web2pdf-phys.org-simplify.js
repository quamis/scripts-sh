
async function cleaner() {
	// invalidate the current function, to avoind double-calls (we will have double calls when the synthetic timer triggers)
	cleaner = function () {
		console.info('already clean');
	}

	console.info('re-populate body');
	$('body')[0].innerHTML =
		$('article.news-article')[0].outerHTML
		;

	console.info('remove some items');
	$('.ads').remove();
	$('.article-banner').remove();

	$('#story_source').remove();
	$(".article-main__more").remove();
	$(".d-none").remove();

	$(".article-gallery").css({
		width: "75%",
		"text-align": "center",
		"margin": "auto",
	});

	console.info('make transparent backgrounds');
	$('body').css('background-color', 'transparent');

	// all done, signal wkhtmltopdf we're done
	window.status = "clean";
	return Promise.resolve("clean");
}

scrollToBottom = function () {
	window.scrollTo(0, 0);

	return new Promise((resolve) => {
		cleaner_timerScroller = setInterval(() => {
			// if ((window.scrollY / window.scrollMaxY) >= 0.99) {
				if ((window.scrollY / $('.article-interaction').position().top) >= 0.99) {
				// scroll through 99% of the page, stop scrolling
				clearInterval(cleaner_timerScroller);
				cleaner_timerScroller = null;
				window.scrollTo(0, 0);

				resolve('scrolled');
			}
			else {
				window.scrollBy(0, window.innerHeight / 1.75);
			}
		}, 200);
	});
}

function wait(seconds) {
	return new Promise(resolve => {
		setTimeout(() => {
			resolve('waited');
		}, seconds * 1000);
	});
}


scrollToBottom()
	.then(() => {
		return wait(5);
	})
	.then(() => {
		return cleaner();
	})
	.then(() => {
		window.print();
	});



// // setup the timer on page load
// window.onload = function () {
// 	console.info('window.onload: setup timer');
// 	setTimeout(function () {
// 		cleaner();
// 	}, 2000);
// };

// // if page load wasn't triggered, setup a synthetic timer
// setTimeout(function () {
// 	console.info('setTimeout: synthetic timer');
// 	cleaner();
// }, 9000);
