function doPost(e) {
  try {
    const expectedSecret = PropertiesService.getScriptProperties()
      .getProperty('COPY_SLIDES_SECRET');
    const body = JSON.parse((e.postData && e.postData.contents) || '{}');

    if (!expectedSecret || body.secret !== expectedSecret) {
      return ContentService
        .createTextOutput(JSON.stringify({ ok: false, error: 'unauthorized' }))
        .setMimeType(ContentService.MimeType.JSON);
    }

    const result = copySlides(
      body.sourcePresentationId,
      body.destinationPresentationId,
      body.sourceSlideObjectId || null,
      body.sourceSlideIndex || null,
      body.insertionIndex || null
    );

    return ContentService
      .createTextOutput(JSON.stringify(result))
      .setMimeType(ContentService.MimeType.JSON);
  } catch (err) {
    return ContentService
      .createTextOutput(JSON.stringify({
        ok: false,
        error: String(err && err.message || err),
      }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}

function copySlides(
  sourcePresentationId,
  destinationPresentationId,
  sourceSlideObjectId,
  sourceSlideIndex,
  insertionIndex
) {
  try {
    if (!sourceSlideObjectId && !sourceSlideIndex) {
      throw new Error(
        'sourceSlideObjectId or sourceSlideIndex is required'
      );
    }

    const sourcePresentation = SlidesApp.openById(sourcePresentationId);
    const destinationPresentation = SlidesApp.openById(destinationPresentationId);
    const sourceSlides = sourcePresentation.getSlides();

    const sourceSlide = sourceSlideObjectId
      ? sourceSlides.find((slide) => slide.getObjectId() === sourceSlideObjectId)
      : sourceSlides[sourceSlideIndex - 1];

    if (!sourceSlide) {
      throw new Error('Source slide not found');
    }

    const importedSlide = insertionIndex
      ? destinationPresentation.insertSlide(
          insertionIndex - 1,
          sourceSlide,
          SlidesApp.SlideLinkingMode.LINKED
        )
      : destinationPresentation.appendSlide(
          sourceSlide,
          SlidesApp.SlideLinkingMode.LINKED
        );

    return {
      ok: true,
      newSlideObjectId: importedSlide.getObjectId(),
      sourceSlideObjectId: sourceSlide.getObjectId(),
    };
  } catch (err) {
    return {
      ok: false,
      error: String(err && err.message || err),
    };
  }
}
