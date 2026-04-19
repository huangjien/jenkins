package org.company.ci

class Utils implements Serializable {
  static String sanitizeBranch(String branchName) {
    return branchName?.replaceAll('[^a-zA-Z0-9._-]', '-')
  }
}
