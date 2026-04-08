async page => {
  const rect = await page.evaluate(() => {
    const canvas = document.querySelector('[data-admin--map-target="canvas"]');
    const r = canvas.getBoundingClientRect();
    return { x: r.x, y: r.y, w: r.width, h: r.height };
  });
  const points = [
    {x: rect.x + rect.w * 0.45, y: rect.y + rect.h * 0.35},
    {x: rect.x + rect.w * 0.55, y: rect.y + rect.h * 0.45},
    {x: rect.x + rect.w * 0.40, y: rect.y + rect.h * 0.30},
    {x: rect.x + rect.w * 0.60, y: rect.y + rect.h * 0.55},
    {x: rect.x + rect.w * 0.50, y: rect.y + rect.h * 0.40},
    {x: rect.x + rect.w * 0.35, y: rect.y + rect.h * 0.45},
    {x: rect.x + rect.w * 0.48, y: rect.y + rect.h * 0.52},
  ];
  for (const pt of points) {
    await page.mouse.click(Math.round(pt.x), Math.round(pt.y));
    await page.waitForTimeout(700);
    const hidden = await page.evaluate(() => document.getElementById('sensor-side-sheet').classList.contains('hidden'));
    if (!hidden) { return 'opened at ' + JSON.stringify(pt); }
  }
  return 'sidesheet not opened - no station hit';
}
