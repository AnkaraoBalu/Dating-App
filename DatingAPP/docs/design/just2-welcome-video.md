# Just2 rooftop welcome video

## Production status — 14 October 2026

The reference photograph and optimized poster have been generated. **The animated MP4 has not been generated.** Video generation requires a connected video service. Runway was found in the plugin directory and suggested; its connection is not yet confirmed.

Generated with the built-in imagegen tool, followed by a composition edit. The first pass was seated; the selected final frame shows the couple standing. The final attached empty rooftop reference was used for environment and color direction.

## Saved assets

- `../../assets/images/welcome/just2_rooftop_reference.png`: selected native generated image, 941 × 1672 pixels.
- `../../assets/images/welcome/just2_rooftop_poster.jpg`: 720 × 1280 JPEG derivative for mobile playback loading/fallback, exported with macOS sips at quality 90.

The small native aspect-ratio difference is normalized in the poster export. The source has not been advertised as native 1080p. A final matching video poster should be extracted from the first frame of the finished video.

The new assets are saved for production and are not yet wired into the existing welcome screen or added to the Flutter bundle.

## Video generation brief

Use the saved reference PNG as the first-frame image. Generate one continuous eight-second ultra-realistic cinematic shot, portrait 9:16, target 1080 × 1920, 24 frames per second, silent.

Preserve the two clearly adult South Asian people (aged 25–29), their identities, their natural anatomy, the woman's wavy hair and cream casual outfit, and the man's softly styled dark hair and deep forest-green shirt. They stand close together on an elegant rooftop overlooking a softly blurred Indian skyline at golden hour.

Their interaction is candid, intimate, playful and subtle: soft eye contact, relaxed smiles, a short gentle shared laugh, realistic breathing, and a light evening breeze through hair and fabric. Natural skin texture, understated expressions, warm peach and coral light, soft golden bokeh, delicate lens bloom, shallow depth of field and very fine film grain. Keep exposure, skyline and color stable.

Composition: couple in the upper-middle, faces and important gestures within the center 75% of the width, open sky near the top for later branding, lower 30% calm and slightly darker with no important facial or hand details. Do not bake branding or UI into the video.

Motion is extremely smooth and restrained. Use an almost imperceptible push-in. Keep total framing change tiny enough that the final pose, expression, exposure and composition can settle close to the opening for a natural loop.

### Timeline

- 0–2 seconds: establish the couple and sunset; very gentle camera motion.
- 2–4 seconds: soft eye contact and a small genuine smile.
- 4–6 seconds: a quiet shared laugh; subtle hair and fabric movement.
- 6–8 seconds: expressions and posture settle back toward the opening moment.

### Exclusions

No text, captions, logos, watermarks, UI, split screens, cuts, scene changes, additional foreground people, rapid movement, sudden zooms, exaggerated expressions, facial warping, extra fingers, unnatural hands, flicker or unstable background geometry.

### Delivery and review

- Final delivery: silent H.264 MP4, portrait 1080 × 1920, eight seconds, constant 24 fps.
- Mobile derivative: 720 × 1280, target approximately 2–5 MB if visually justified; smaller is acceptable if quality is retained.
- Retain the original video export as the master.
- Review motion, anatomy, framing and first/last-frame continuity before accepting the video.
- If needed, use a short loop crossfade only where poses match; avoid ghosted or duplicated faces. Preserve the final eight-second duration.
- Extract the exact opening frame as the final loading poster.
- Flutter playback: preload, autoplay silently, loop, show the matching poster while initializing or on errors, pause when backgrounded, resume only when the screen is active, and respect reduced-motion preferences.
- Render the dark forest-green-to-transparent CTA gradient in Flutter over the footage.

## Exact first-frame generation prompt

Use case: photorealistic-natural.
Asset type: the opening frame and poster image for an eight-second cinematic welcome-screen background video for the modern dating app just2.
Input image: use only the final attached reference, the EMPTY rooftop terrace with peach sunset, plants, glass railing and hazy Indian skyline, as an environment and color reference. Create a new portrait scene with two adults; this is a photographic still to be animated later.
Format: strictly vertical 9:16, target 1080 x 1920, full bleed, one single photograph.
Scene: stylish understated rooftop terrace at golden hour above a softly blurred Indian city skyline. Warm peach-pink sky, faint golden bokeh lights, subtle peripheral plants and elegant glass railing. Premium natural lifestyle photography.
Subjects: two natural-looking attractive South Asian young adults aged 25–29, visibly adult, close together facing each other with gentle genuine smiles and soft eye contact, a candid moment just before a quiet shared laugh. Woman with naturally wavy dark hair and elegant cream casual outfit. Man with softly styled dark hair, relaxed deep forest-green linen shirt. Real skin texture, realistic facial proportions, anatomy and hands, understated styling.
Composition: eye-level medium-wide portrait, both faces completely visible in the central upper-middle, around 32–44 percent down the image. Keep the couple comfortably within central 75 percent of width. Leave top 15 percent relatively clean for a logo to be overlaid later. The bottom 30 percent contains only calm softly blurred, naturally darker foreground terrace and subtle forest tones, no important faces or hands or detailed objects. Faces remain the clear focus. No overly close crop and no heads near frame edges.
Lighting: warm peach and coral sunset gently illuminates skin, delicate rim light on hair, soft golden bokeh, restrained lens bloom, shallow depth of field, very fine film grain, elegant cream/peach/coral/deep-forest palette. Realistic warm light, not saturated orange.
Mood: intimate, playful, authentic, calm, luxurious.
Constraints: NO text, no letters, no just2 wordmark, no logo, no captions, no UI elements, no button, no watermark, no frame, no collage, no dramatic pose, no exaggerated laughing, no unnatural hands, no distorted faces, no waxy skin, no illustration. Deliver one high-quality portrait photograph.

## Exact composition refinement prompt

Edit this generated rooftop photograph into the required first frame for a vertical dating-app welcome video. Preserve the same two visibly adult South Asian people, their faces, her wavy hair and cream outfit, his forest-green shirt, their gentle eye contact, the premium photorealism and the warm peach Indian-city rooftop setting.
Change ONLY the pose and framing: the couple should be STANDING close together on the terrace, relaxed, facing each other with small natural smiles, seen in an eye-level MEDIUM-WIDE portrait shot from a greater camera distance. Their heads should be placed around 32–40% of image height from the TOP, not halfway down. Both people including shoulders should fit comfortably between x=15% and x=85% of frame width, without being clipped by image edges. Their relaxed hands are at waist level and unobtrusive. No hand resting on chin; no seated pose; no sofa. The top 15% is open soft peach sky. The bottom 30% is a quiet naturally darker, out-of-focus foreground terrace/plants with no faces, no hands, and no important detail; create this through optical foreground blur, not a flat black block or vignette. Couple's faces remain the focus in the central UPPER-middle. This is an understated candid romantic moment before a subtle shared laugh.
One single full-bleed photograph, strictly 9:16 vertical, target 1080x1920. No text, no logo, no UI, no captions, no watermark, no borders, no collages. Natural skin, realistic hands, no distorted bodies, no excessive orange saturation.

