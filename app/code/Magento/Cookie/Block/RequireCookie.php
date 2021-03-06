<?php
/**
 * Copyright © 2013-2017 Magento, Inc. All rights reserved.
 * See COPYING.txt for license details.
 */

/**
 * Frontend form key content block
 */
namespace Magento\Cookie\Block;

class RequireCookie extends \Magento\Framework\View\Element\Template
{
    /**
     * Retrieve script options encoded to json
     *
     * @return string
     */
    public function getScriptOptions()
    {
        $params = ['noCookieUrl' => $this->getUrl('cookie/index/noCookies/'), 'triggers' => $this->getTriggers()];
        return json_encode($params);
    }
}
