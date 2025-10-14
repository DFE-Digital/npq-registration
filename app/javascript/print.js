window.formattedPrint = (target) => {
  let path = target.dataset.path;
  const printWindow = window.open(path, "_blank");
  printWindow.onafterprint = window.close;
  printWindow.print();
};
