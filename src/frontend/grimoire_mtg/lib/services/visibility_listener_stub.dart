typedef VisibilityCallback = void Function(bool isVisible);

void listenForVisibility(VisibilityCallback onChanged) {}

void disposeVisibilityListener() {}
