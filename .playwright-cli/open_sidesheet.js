async page => {
  await page.evaluate(() => {
    const sidesheet = document.getElementById('sensor-side-sheet');
    const frame = sidesheet.querySelector('turbo-frame');
    frame.src = '/admin/monitoring_stations/1';
    sidesheet.classList.remove('hidden');
  });
  await page.waitForTimeout(1500);
  return 'done';
}
