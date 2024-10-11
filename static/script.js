// start https://stackoverflow.com/a/15506705
const addStyle = (() => {
	const style = document.createElement("style");
	document.head.append(style);
	return (styleString) => (style.textContent = styleString);
})();
// end https://stackoverflow.com/a/15506705

const checkbox = document.getElementById("debug");
const localDebug = localStorage.getItem("debug");
if (localDebug !== null) {
	checkbox.checked = localDebug == "true";
}

function setOutline(value) {
	if (value) {
		addStyle("* {outline: 1px dotted red;}");
	} else {
		addStyle("");
	}
}

setOutline(checkbox.checked);
function setDebug(value) {
	localStorage.setItem("debug", value.toString());
	setOutline(value);
}

checkbox.addEventListener("change", function () {
	setDebug(checkbox.checked);
});

// start https://stackoverflow.com/a/75124760
function getPreferredColorScheme() {
	let systemScheme = "light";
	if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
		systemScheme = "dark";
	}
	let chosenScheme = systemScheme;
	if (localStorage.getItem("scheme")) {
		chosenScheme = localStorage.getItem("scheme");
	}
	if (systemScheme === chosenScheme) {
		localStorage.removeItem("scheme");
	}
	return chosenScheme;
}

function savePreferredColorScheme(scheme) {
	let systemScheme = "light";
	if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
		systemScheme = "dark";
	}
	if (systemScheme === scheme) {
		localStorage.removeItem("scheme");
	} else {
		localStorage.setItem("scheme", scheme);
	}
}

function setScheme(newScheme) {
	applyPreferredColorScheme(newScheme);
	savePreferredColorScheme(newScheme);
}

// TODO: could be changed to match single stylesheet
function applyPreferredColorScheme(scheme) {
	for (var s = 0; s < document.styleSheets.length; s++) {
		for (var i = 0; i < document.styleSheets[s].cssRules.length; i++) {
			rule = document.styleSheets[s].cssRules[i];
			if (
				rule &&
				rule.media &&
				rule.media.mediaText.includes("prefers-color-scheme")
			) {
				switch (scheme) {
					case "light":
						rule.media.appendMedium("original-prefers-color-scheme");
						if (rule.media.mediaText.includes("light"))
							rule.media.deleteMedium("(prefers-color-scheme: light)");
						if (rule.media.mediaText.includes("dark"))
							rule.media.deleteMedium("(prefers-color-scheme: dark)");
						break;
					case "dark":
						rule.media.appendMedium("(prefers-color-scheme: light)");
						rule.media.appendMedium("(prefers-color-scheme: dark)");
						if (rule.media.mediaText.includes("original"))
							rule.media.deleteMedium("original-prefers-color-scheme");
						break;
					default:
						rule.media.appendMedium("(prefers-color-scheme: dark)");
						if (rule.media.mediaText.includes("light"))
							rule.media.deleteMedium("(prefers-color-scheme: light)");
						if (rule.media.mediaText.includes("original"))
							rule.media.deleteMedium("original-prefers-color-scheme");
						break;
				}
			}
		}
	}
}

applyPreferredColorScheme(getPreferredColorScheme());
// end https://stackoverflow.com/a/75124760

const addFontSize = (() => {
	const html = document.querySelector("html");
	const currentSize = parseFloat(
		window.getComputedStyle(html, null).getPropertyValue("font-size"),
	);
	const localSize = localStorage.getItem("size");
	if (localSize !== null) {
		html.style.fontSize = localSize;
	} else {
		html.style.fontSize = currentSize + "px";
	}
	return (addPx) => {
		// finding web browsers based on hovering capability
		// https://stackoverflow.com/a/52854585
		if (
			(window.matchMedia("(any-hover: hover)").matches &&
				window.devicePixelRatio != 1) ||
			window.visualViewport.scale != 1
		) {
			return;
		}
		html.style.fontSize = parseInt(html.style.fontSize, 10) + addPx + "px";
		localStorage.setItem("size", html.style.fontSize);
	};
})();
