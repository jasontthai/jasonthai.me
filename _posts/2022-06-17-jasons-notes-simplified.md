---
title: Jason's Notes Simplified
category: blog
description: A cleaner and more minimal Jason's Notes
tags:
  - design
---

<style>

.mySlides {display: none}
img {vertical-align: middle;}

/* Slideshow container */
.slideshow-container {
  max-width: 1000px;
  position: relative;
  margin: auto;
}

/* Next & previous buttons */
.prevImg, .nextImg {
  cursor: pointer;
  position: absolute;
  top: 50%;
  width: auto;
  padding: 16px;
  margin-top: -22px;
  color: white;
  font-weight: bold;
  font-size: 18px;
  transition: 0.6s ease;
  border-radius: 0 3px 3px 0;
  user-select: none;
}

/* Position the "next button" to the right */
.nextImg {
  right: 0;
  border-radius: 3px 0 0 3px;
}

/* On hover, add a black background color with a little bit see-through */
.prevImg:hover, .nextImg:hover {
  background-color: rgba(0,0,0,0.8);
}

/* Caption text */
.textImg {
  color: #f2f2f2;
  font-size: 15px;
  padding: 8px 12px;
  position: absolute;
  bottom: 8px;
  width: 100%;
  text-align: center;
}

/* Number text (1/3 etc) */
.numbertextImg {
  color: #f2f2f2;
  font-size: 12px;
  padding: 8px 12px;
  position: absolute;
  top: 0;
}

/* The dots/bullets/indicators */
.dot {
  cursor: pointer;
  height: 15px;
  width: 15px;
  margin: 0 2px;
  background-color: #bbb;
  border-radius: 50%;
  display: inline-block;
  transition: background-color 0.6s ease;
}

.active, .dot:hover {
  background-color: #717171;
}

/* Fading animation */
.fade {
  -webkit-animation-name: fade;
  -webkit-animation-duration: 1.5s;
  animation-name: fade;
  animation-duration: 1.5s;
}

@-webkit-keyframes fade {
  from {opacity: .4} 
  to {opacity: 1}
}

@keyframes fade {
  from {opacity: .4} 
  to {opacity: 1}
}

/* On smaller screens, decrease text size */
@media only screen and (max-width: 300px) {
  .prevImg, .nextImg,.textImg {font-size: 11px}
}
</style>

This is a bit overdue but I've finally updated this blog's layout. Here is the list of all the changes so far:

* No more sticky sidebar with my profile picture.  Frankly I don't want to keep looking at it everytime I visit this blog.
* No more images on home page. Even though having the images is nice, I want to make the homepage more minimalistic.
* I've added a new hamburger menu for nav bar in mobile view. Yay to CSS.
* This blog now is both Light and Dark mode compatible. Try switching your computer's theme and see which one you like more. I've included the images of both versions below. I still have not added the ability to toggle between the two modes. Maybe that's what I will do next but it doesn't seem that important to me.
* Migrated from [Tachyons CSS](https://tachyons.io/)  to [Tailwind CSS](https://tailwindcss.com/). Tailwind CSS provides more robust options to declare dark mode styles inline.
* CSS declaration is more clean and precise (in my perspective).
* I also do some house cleaning to the blog's infrastructure: removed unused Jekyll's gems, cleaned up dangling reference from minima theme, etc.

I like how the blog looks now but knowing me,  I will eventually have to scratch the itch of updating how the site looks again. 

## Screenshots
<!-- Slideshow container -->
<div class="slideshow-container">

<!-- Full-width images with number and caption text -->
<div class="mySlides fade">
<div class="numbertextImg">Dark Mode</div>
<img src="/assets/img/dark-mode.png" alt="Dark Mode">
</div>

<div class="mySlides fade">
<div class="numbertextImg">Light Mode</div>
<img src="/assets/img/light-mode.png" alt="Light Mode">
</div>

<!-- Next and previous buttons -->
<a class="prevImg" onclick="plusSlides(-1)">&#10094;</a>
<a class="nextImg" onclick="plusSlides(1)">&#10095;</a>
</div>
<br>

<!-- The dots/circles -->
<div style="text-align:center">
<span class="dot" onclick="currentSlide(1)"></span> 
<span class="dot" onclick="currentSlide(2)"></span> 
</div>

<script type="text/javascript">
var slideIndex = 1;
showSlides(slideIndex);

function plusSlides(n) {
  showSlides(slideIndex += n);
}

function currentSlide(n) {
  showSlides(slideIndex = n);
}

function showSlides(n) {
  var i;
  var slides = document.getElementsByClassName("mySlides");
  var dots = document.getElementsByClassName("dot");
  if (n > slides.length) {slideIndex = 1}    
  if (n < 1) {slideIndex = slides.length}
  for (i = 0; i < slides.length; i++) {
      slides[i].style.display = "none";  
  }
  for (i = 0; i < dots.length; i++) {
      dots[i].className = dots[i].className.replace(" active", "");
  }
  slides[slideIndex-1].style.display = "block";  
  dots[slideIndex-1].className += " active";
}
</script>
